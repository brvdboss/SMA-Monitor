# $dict should be the dictionary for mapping template variables to JSON entities.
# WARNING: this definition does not support template-variables being 
# recognized as such in key names.
reduce paths as $p (.;
  getpath($p) as $v
  | if $v|type == "string" and $dict[$v] then setpath($p; $dict[$v]) else . end)