def tos: if type == "number" then . else tojson end;
def ar: if type == "string" then "." + . else "[\(.)]" end;
def path2text($value):
	reduce .[] as $segment ("";
		. + ($segment | ar));
paths(scalars) as $p | getpath($p) as $v | $p | {(path2text($p)):$v}