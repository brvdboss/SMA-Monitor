#Start with constructing an array so we can merge different segments at the end with 'add'
[
.result | to_entries[] |
({serial: .key}), 								# serial nr of the inverter
{name: "solar-inverter"}, 						# what kind of device are we talking about
{time: now},									# add the current time to it as a timestamp
{inverter: env.INVERTER_HOST},					# the hostname of the inverter that we got from an environment variable

(	# This block belongs together
	
	#define some convenience functions
	def tos: if type == "number" then . else tojson end;		# print a number or encode a string
	def ar: if type == "string" then "" + . else "_\(.)" end;	# add a _ prefix to array indices
	def path2text($value):										# write the full path + value for a key
		reduce .[] as $segment ("";
			. + ($segment | ar));
			

	#grab the content we want
	.value | to_entries |
	
	# below is the dictionary as explained in the cookbook https://github.com/stedolan/jq/wiki/Cookbook
	# to translate the keys (like 6180_08414B00) to their readable formats
	# $dict should be the dictionary for mapping template variables to JSON entities.
	# WARNING: this definition does not support template-variables being 
	# recognized as such in key names.
	reduce paths as $p (.;
	  getpath($p) as $v
	  | if $v|type == "string" and $dict[$v] then setpath($p; $dict[$v]) else . end)
	  
	| from_entries 								#restore to previous state with human readable keynames
	
	# they all hae a child key "1".  get rid of it as it doesn't add any value
	| to_entries[] | [{key: .key, value: .value."1"}] | from_entries
	# remove all the val-keys, they don't add any value
	| [
		. | to_entries[] |
		(
		#We assume there is one or two items in the val array. (2 trackers)
		if ( .value[1].val != null )
		then (
			{key: (.key+" A"), value: .value[0].val},
			{key: (.key+" B"), value: .value[1].val}
			)
		else (
			{key: (.key), value: .value[0].val}
			)
		end
		)
	  ]
	| from_entries
	
	# select those with tag (do dictionary thing), select those without tag (pass as is)
	# We assume there is only one item in the tag array
	| to_entries[] 
	|
		if( .value| type == "array")
		then (
			#--argfile dict2 locale.json
			[{key: .key, value: (.value[0].tag)|tostring}] | from_entries |
			reduce paths as $p (.;
				getpath($p) as $v
				| if $v|type == "string" and $dict2[$v] then setpath($p; $dict2[$v]) else . end)
			)
		else (
			#pass unchanged
			[.] |from_entries
			)
		end
	
	# now flatten the structure by putting it in the name of the key
	#| paths(scalars) as $p | getpath($p) as $v | $p | {(path2text($p)):$v}
)
] | add




