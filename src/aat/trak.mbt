// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

let f16dot16_scale : Double = 1.0 / 65536.0

///|
/// Track table entry.
pub(all) struct TrackTableEntry {
  track : Int
  name_id : Int
  values : Array[Int]
} derive(Eq, Debug, ToJson)

fn TrackTableEntry::track_value(self : TrackTableEntry) -> Double {
  self.track.to_double() * f16dot16_scale
}

fn TrackTableEntry::value_for_size(
  self : TrackTableEntry,
  ptem : Double,
  size_table : Array[Int],
) -> Double {
  let n_sizes = size_table.length()
  if n_sizes == 0 {
    return 0.0
  }
  if n_sizes == 1 {
    return self.values[0].to_double()
  }

  let mut i = 0
  for idx in 0..<n_sizes {
    let size_value = size_table[idx].to_double() * f16dot16_scale
    if size_value >= ptem {
      i = idx
      break
    }
    if idx == n_sizes - 1 {
      i = n_sizes
    }
  }

  if i == 0 {
    return self.values[0].to_double()
  }
  if i >= n_sizes {
    return self.values[n_sizes - 1].to_double()
  }

  let s0 = size_table[i - 1].to_double() * f16dot16_scale
  let s1 = size_table[i].to_double() * f16dot16_scale
  let v0 = self.values[i - 1].to_double()
  let v1 = self.values[i].to_double()

  if s1 < s0 {
    if ptem <= s1 {
      return v1
    }
    if ptem >= s0 {
      return v0
    }
    if s0 == s1 {
      return (v0 + v1) * 0.5
    }
    let t = (ptem - s1) / (s0 - s1)
    return v1 + t * (v0 - v1)
  }

  if ptem <= s0 {
    return v0
  }
  if ptem >= s1 {
    return v1
  }
  if s0 == s1 {
    return (v0 + v1) * 0.5
  }
  let t = (ptem - s0) / (s1 - s0)
  v0 + t * (v1 - v0)
}

///|
/// Track data for a direction.
pub(all) struct TrackData {
  track_table : Array[TrackTableEntry]
  size_table : Array[Int]
} derive(Eq, Debug, ToJson)

fn TrackData::tracking(
  self : TrackData,
  ptem : Double,
  track : Double,
) -> Double {
  let count = self.track_table.length()
  if count == 0 {
    return 0.0
  }
  if count == 1 {
    return self.track_table[0].value_for_size(ptem, self.size_table)
  }

  let mut i = 0
  let mut j = count - 1
  while i + 1 < count && self.track_table[i + 1].track_value() <= track {
    i = i + 1
  }
  while j > 0 && self.track_table[j - 1].track_value() >= track {
    j = j - 1
  }

  if i == j {
    return self.track_table[i].value_for_size(ptem, self.size_table)
  }

  let t0 = self.track_table[i].track_value()
  let t1 = self.track_table[j].track_value()
  let t = (track - t0) / (t1 - t0)
  let a = self.track_table[i].value_for_size(ptem, self.size_table)
  let b = self.track_table[j].value_for_size(ptem, self.size_table)
  a + t * (b - a)
}

///|
/// Parsed trak table.
pub struct TrakTable {
  version : Int
  format : Int
  horiz : TrackData?
  vert : TrackData?
} derive(Eq, Debug, ToJson)

///|
/// Parse a trak table.
pub fn TrakTable::parse(data : BytesView) -> Result[TrakTable, AatError] {
  let version = read_i32(data, 0)
  let format = read_u16_int(data, 4)
  let horiz_offset = read_u16_int(data, 6)
  let vert_offset = read_u16_int(data, 8)
  let reserved = read_u16_int(data, 10)
  match (version, format, horiz_offset, vert_offset, reserved) {
    (Err(err), _, _, _, _) => Err(err)
    (_, Err(err), _, _, _) => Err(err)
    (_, _, Err(err), _, _) => Err(err)
    (_, _, _, Err(err), _) => Err(err)
    (_, _, _, _, Err(err)) => Err(err)
    (Ok(version), Ok(format), Ok(horiz_offset), Ok(vert_offset), Ok(_)) => {
      let mut horiz : TrackData? = None
      let mut vert : TrackData? = None
      if horiz_offset != 0 {
        let parsed = parse_track_data(data, horiz_offset)
        match parsed {
          Err(err) => return Err(err)
          Ok(value) => horiz = Some(value)
        }
      }
      if vert_offset != 0 {
        let parsed = parse_track_data(data, vert_offset)
        match parsed {
          Err(err) => return Err(err)
          Ok(value) => vert = Some(value)
        }
      }
      Ok(TrakTable::{ version, format, horiz, vert })
    }
  }
}

///|
/// True if trak table has usable data.
pub fn TrakTable::has_data(self : TrakTable) -> Bool {
  self.version != 0
}

///|
/// Compute tracking adjustment in design units.
pub fn TrakTable::tracking(
  self : TrakTable,
  ptem : Double,
  horizontal : Bool,
  track? : Double = 0.0,
) -> Double {
  let data = if horizontal { self.horiz } else { self.vert }
  match data {
    None => 0.0
    Some(data) => data.tracking(ptem, track)
  }
}

fn parse_track_data(
  data : BytesView,
  offset : Int,
) -> Result[TrackData, AatError] {
  if offset < 0 || offset + 8 > data.length() {
    return Err(UnexpectedEof)
  }
  let n_tracks = read_u16_int(data, offset)
  let n_sizes = read_u16_int(data, offset + 2)
  let size_table_offset = read_u32_int(data, offset + 4)
  match (n_tracks, n_sizes, size_table_offset) {
    (Err(err), _, _) => Err(err)
    (_, Err(err), _) => Err(err)
    (_, _, Err(err)) => Err(err)
    (Ok(n_tracks), Ok(n_sizes), Ok(size_table_offset)) => {
      if n_tracks < 0 || n_sizes < 0 {
        return Err(InvalidFormat)
      }
      let size_abs = size_table_offset
      if size_abs < 0 || size_abs + n_sizes * 4 > data.length() {
        return Err(UnexpectedEof)
      }
      let size_table : Array[Int] = []
      for i in 0..<n_sizes {
        let size_value = read_i32(data, size_abs + i * 4)
        match size_value {
          Err(err) => return Err(err)
          Ok(value) => size_table.push(value)
        }
      }

      let entry_size = 8
      let table_offset = offset + 8
      if table_offset < 0 || table_offset + n_tracks * entry_size > data.length() {
        return Err(UnexpectedEof)
      }
      let track_table : Array[TrackTableEntry] = []
      for i in 0..<n_tracks {
        let entry_offset = table_offset + i * entry_size
        let track = read_i32(data, entry_offset)
        let name_id = read_u16_int(data, entry_offset + 4)
        let values_offset = read_u16_int(data, entry_offset + 6)
        match (track, name_id, values_offset) {
          (Err(err), _, _) => return Err(err)
          (_, Err(err), _) => return Err(err)
          (_, _, Err(err)) => return Err(err)
          (Ok(track), Ok(name_id), Ok(values_offset)) => {
            let values_abs = values_offset
            if values_abs < 0 || values_abs + n_sizes * 2 > data.length() {
              return Err(UnexpectedEof)
            }
            let values : Array[Int] = []
            for j in 0..<n_sizes {
              let value = read_i16(data, values_abs + j * 2)
              match value {
                Err(err) => return Err(err)
                Ok(value) => values.push(value)
              }
            }
            track_table.push(TrackTableEntry::{ track, name_id, values })
          }
        }
      }
      Ok(TrackData::{ track_table, size_table })
    }
  }
}
