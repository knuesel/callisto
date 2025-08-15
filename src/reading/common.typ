#let ensure-array(x) = if type(x) == array { x } else { (x,) }

// A dictionary of cell-related data, to be used as one field in the result
// dict.
#let _cell-output-dict(cell) = (
  index: cell.index,
  id: cell.id,
  metadata: cell.metadata,
  type: cell.cell_type,
) + if cell.cell_type == "code" {
  (execution-count: cell.execution_count)
}

/// Return either the 'value' key of dict or return the dict itself, with some
/// added cell data under key 'cell'. See cell-output-dict for the added data.
/// - cell (dict): A cell in json format
/// - result-spec (str): Choose output mode: "value" or "dict"
/// - dict (dict): Contains at least a 'value' key
/// -> any | (value: any, cell: dict)
#let final-result(cell, result-spec, dict) = {
  if result-spec == "value" {
    return dict.value
  }
  if result-spec == "dict" {
    dict.cell = _cell-output-dict(cell)
    return dict
  }
  panic("invalid result specification: " + repr(result))
}

#let single-item(items, item: "unique") = {
  if items.len() == 0 {
    panic("No matching item found")
  }
  if item == "unique" {
    if items.len() != 1 {
      panic("expected 1 item, found " + str(items.len()))
    }
    item = 0
  }
  return items.at(item)
}
