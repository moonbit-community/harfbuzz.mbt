///|
priv struct OrderEdge {
  target : Int
  width : Int
}

///|
pub struct OverflowRecord {
  parent : Int
  child : Int
  offset : Int
  min : Int
  max : Int
  width : Int
  is_signed : Bool
} derive(Eq, Show)

let inf_distance : Int64 = Int64::from_int(1) << 60
let space_stride : Int64 = Int64::from_int(1) << 32

fn edge_weight(width : Int, child_size : Int) -> Int64 {
  let size = Int64::from_int(child_size)
  if width <= 0 {
    return size
  }
  let limit = Int64::from_int(1) << (width * 8)
  size + limit
}

fn collect_order_edges(
  objects : ArrayView[SerializeObject],
) -> Result[(Array[Array[OrderEdge]], Array[Int]), SerializeError] {
  let count = objects.length()
  let edges : Array[Array[OrderEdge]] = []
  let indegree : Array[Int] = Array::make(count, 0)
  for _ in 0..<count {
    edges.push([])
  }
  for i in 0..<count {
    let obj = objects[i]
    for target in obj.virtual_links {
      if target < 0 || target >= count {
        return Err(SerializeError::InvalidLink)
      }
      edges[i].push(OrderEdge::{ target, width: 0 })
      indegree[target] = indegree[target] + 1
    }
    for link in obj.real_links {
      if link.objidx < 0 || link.objidx >= count {
        return Err(SerializeError::InvalidLink)
      }
      if link.width == 0 {
        edges[i].push(OrderEdge::{ target: link.objidx, width: 0 })
        indegree[link.objidx] = indegree[link.objidx] + 1
        continue
      }
      if link.is_signed {
        continue
      }
      if link.whence == SerializeWhence::Absolute {
        continue
      }
      edges[i].push(OrderEdge::{ target: link.objidx, width: link.width })
      indegree[link.objidx] = indegree[link.objidx] + 1
    }
  }
  Ok((edges, indegree))
}

fn assign_spaces(edges : Array[Array[OrderEdge]]) -> Array[Int] {
  let count = edges.length()
  let spaces : Array[Int] = Array::make(count, 0)
  let reachable : Array[Bool] = Array::make(count, false)
  let queue : Array[Int] = []
  for i in 0..<count {
    for edge in edges[i] {
      if edge.width >= 4 {
        queue.push(edge.target)
      }
    }
  }
  let mut index = 0
  while index < queue.length() {
    let node = queue[index]
    index = index + 1
    if reachable[node] {
      continue
    }
    reachable[node] = true
    for edge in edges[node] {
      if !reachable[edge.target] {
        queue.push(edge.target)
      }
    }
  }
  if queue.length() == 0 {
    return spaces
  }
  let undirected : Array[Array[Int]] = []
  for _ in 0..<count {
    undirected.push([])
  }
  for i in 0..<count {
    for edge in edges[i] {
      undirected[i].push(edge.target)
      undirected[edge.target].push(i)
    }
  }
  let visited : Array[Bool] = Array::make(count, false)
  let mut space_id = 1
  for i in 0..<count {
    if reachable[i] && !visited[i] {
      let component : Array[Int] = [i]
      visited[i] = true
      let mut head = 0
      while head < component.length() {
        let node = component[head]
        head = head + 1
        spaces[node] = space_id
        for next in undirected[node] {
          if reachable[next] && !visited[next] {
            visited[next] = true
            component.push(next)
          }
        }
      }
      space_id = space_id + 1
    }
  }
  spaces
}

fn compute_shortest_dist(
  objects : ArrayView[SerializeObject],
  edges : Array[Array[OrderEdge]],
  indegree : Array[Int],
) -> Array[Int64] {
  let count = objects.length()
  let dist : Array[Int64] = Array::make(count, inf_distance)
  let visited : Array[Bool] = Array::make(count, false)
  for i in 0..<count {
    if indegree[i] == 0 {
      dist[i] = Int64::from_int(0)
    }
  }
  for _ in 0..<count {
    let mut best = -1
    let mut best_dist = inf_distance
    for i in 0..<count {
      if !visited[i] && dist[i] < best_dist {
        best = i
        best_dist = dist[i]
      }
    }
    if best < 0 {
      break
    }
    visited[best] = true
    for edge in edges[best] {
      let weight = edge_weight(edge.width, objects[edge.target].data.length())
      let candidate = dist[best] + weight
      if candidate < dist[edge.target] {
        dist[edge.target] = candidate
      }
    }
  }
  dist
}

fn topo_sort(
  edges : Array[Array[OrderEdge]],
  indegree : Array[Int],
  scores : Array[Int64],
) -> Result[Array[Int], SerializeError] {
  let count = edges.length()
  let indeg = indegree.copy()
  let ready : Array[Int] = []
  for i in 0..<count {
    if indeg[i] == 0 {
      ready.push(i)
    }
  }
  let order : Array[Int] = []
  while ready.length() > 0 {
    let mut best_idx = 0
    let mut best_node = ready[0]
    for i in 1..<ready.length() {
      let node = ready[i]
      if scores[node] < scores[best_node] || (scores[node] == scores[best_node] && node < best_node) {
        best_idx = i
        best_node = node
      }
    }
    let last = ready.length() - 1
    ready[best_idx] = ready[last]
    ignore(ready.pop())
    order.push(best_node)
    for edge in edges[best_node] {
      indeg[edge.target] = indeg[edge.target] - 1
      if indeg[edge.target] == 0 {
        ready.push(edge.target)
      }
    }
  }
  if order.length() != count {
    return Err(SerializeError::VirtualOrder)
  }
  Ok(order)
}

fn compute_starts(
  objects : ArrayView[SerializeObject],
  order : ArrayView[Int],
) -> Result[Array[Int], SerializeError] {
  let count = objects.length()
  if order.length() != count {
    return Err(SerializeError::InvalidLink)
  }
  let starts : Array[Int] = Array::make(count, 0)
  let seen : Array[Bool] = Array::make(count, false)
  let mut offset = 0
  for idx in order {
    if idx < 0 || idx >= count {
      return Err(SerializeError::InvalidLink)
    }
    if seen[idx] {
      return Err(SerializeError::InvalidLink)
    }
    seen[idx] = true
    starts[idx] = offset
    offset = offset + objects[idx].data.length()
  }
  Ok(starts)
}

fn collect_overflows(
  objects : ArrayView[SerializeObject],
  order : ArrayView[Int],
) -> Result[Array[OverflowRecord], SerializeError] {
  let count = objects.length()
  let starts = match compute_starts(objects, order) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let overflows : Array[OverflowRecord] = []
  for i in 0..<count {
    let obj = objects[i]
    for link in obj.real_links {
      if link.width == 0 {
        continue
      }
      if link.objidx < 0 || link.objidx >= count {
        return Err(SerializeError::InvalidLink)
      }
      if link.position < 0 || link.position + link.width > obj.data.length() {
        return Err(SerializeError::OutOfBounds)
      }
      let target_start = starts[link.objidx]
      let origin = match link.whence {
        SerializeWhence::Head => starts[i]
        SerializeWhence::Tail => starts[i] + obj.data.length()
        SerializeWhence::Absolute => 0
      }
      let offset = target_start + link.bias - origin
      if link.is_signed {
        let limits = match signed_limits(link.width) {
          None => return Err(SerializeError::InvalidWidth)
          Some((min, max)) => (min, max)
        }
        if offset < limits.0 || offset > limits.1 {
          overflows.push(OverflowRecord::{
            parent: i,
            child: link.objidx,
            offset,
            min: limits.0,
            max: limits.1,
            width: link.width,
            is_signed: true,
          })
        }
      } else {
        let max_value = match max_value_for_width(link.width) {
          None => return Err(SerializeError::InvalidWidth)
          Some(value) => value
        }
        let max_int = max_value.reinterpret_as_int()
        if offset < 0 || offset > max_int {
          overflows.push(OverflowRecord::{
            parent: i,
            child: link.objidx,
            offset,
            min: 0,
            max: max_int,
            width: link.width,
            is_signed: false,
          })
        }
      }
    }
  }
  Ok(overflows)
}

fn priority_delta(width : Int, child_size : Int) -> Int64 {
  if width <= 0 {
    return Int64::from_int(1)
  }
  edge_weight(width, child_size) + Int64::from_int(1)
}

///|
pub fn repack_object_order(
  objects : ArrayView[SerializeObject],
  max_iterations? : Int = 32,
) -> Result[Array[Int], SerializeError] {
  let count = objects.length()
  if count == 0 {
    return Ok([])
  }
  let (edges, indegree) = match collect_order_edges(objects) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let spaces = assign_spaces(edges)
  let priorities : Array[Int64] = Array::make(count, Int64::from_int(0))
  let mut iter = 0
  while iter < max_iterations {
    let base_dist = compute_shortest_dist(objects, edges, indegree)
    let scores : Array[Int64] = Array::make(count, Int64::from_int(0))
    for i in 0..<count {
      let space_offset = Int64::from_int(spaces[i]) * space_stride
      scores[i] = base_dist[i] + priorities[i] + space_offset
    }
    let order = match topo_sort(edges, indegree, scores) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    let overflows = match collect_overflows(objects, order[:]) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    if overflows.length() == 0 {
      return Ok(order)
    }
    for overflow in overflows {
      let child_size = objects[overflow.child].data.length()
      let delta = priority_delta(overflow.width, child_size)
      priorities[overflow.child] = priorities[overflow.child] - delta
    }
    iter = iter + 1
  }
  Err(SerializeError::OffsetOverflow)
}

///|
pub fn serialize_objects_repacked(
  objects : ArrayView[SerializeObject],
  max_iterations? : Int = 32,
) -> Result[Bytes, SerializeError] {
  let order = match repack_object_order(objects, max_iterations=max_iterations) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  serialize_objects_in_order(objects, order[:])
}

///|
pub fn serialize_objects_repacked_with_order(
  objects : ArrayView[SerializeObject],
  max_iterations? : Int = 32,
) -> Result[(Bytes, Array[Int]), SerializeError] {
  let order = match repack_object_order(objects, max_iterations=max_iterations) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let bytes = match serialize_objects_in_order(objects, order[:]) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  Ok((bytes, order))
}
