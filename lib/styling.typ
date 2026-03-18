// Default doc template
#let default-template(doc) = doc

// Resolve style by name
#let _resolve-name(name, named-styles) = {
  if name not in named-styles {
    panic("style name not found: " + name)
  }
  return named-styles.at(name)
}

#let _resolve-field(key, value, named-styles) = {
  if value == none {
    return none
  }
  if type(value) == function {
    return ((key): value)
  }
  if type(value) == str {
    value = _resolve-name(value, named-styles)
  }
  if type(value) == dictionary {
    // Resolve the field in the value dictionary
    return _resolve-field(key, value.at(key, default: none), named-styles)
  }
  panic("invalid style field type: " + str(type(value)))
}

// Normalize a style name/dict/none to a dict of functions.
// The dict is guaranteed to contain at least the 'template' field.
#let resolve(value, named-styles) = {
  // Start with default value for doc template
  (template: default-template)

  if value == none { return }

  if type(value) == str {
    value = _resolve-name(value, named-styles)
  }
  if type(value) != dictionary {
    panic("invalid style type: " + str(type(value)))
  }
  // Resolve each dict field
  for (k, v) in value {
    _resolve-field(k, v, named-styles)
  }
}
