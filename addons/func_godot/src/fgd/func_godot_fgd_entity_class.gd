@icon("res://addons/func_godot/icons/icon_godot_ranger.svg")
## Base entity definition class. Not to be used directly, use [FuncGodotFGDBaseClass], [FuncGodotFGDSolidClass], or [FuncGodotFGDPointClass] instead.
class_name FuncGodotFGDEntityClass
extends Resource

var prefix: String = ""

@export_group("Entity Definition")

## Entity classname. This is a required field in all entity types as it is parsed by both the map editor and by FuncGodot on map build.
@export var classname : String = ""

## Entity description that appears in the map editor. Not required.
@export var description : String = ""

@export var func_godot_internal : bool = false

## FuncGodotFGDBaseClass resources to inherit class properties and class descriptions from.
@export var base_classes: Array[Resource] = []

## Key value pair properties that will appear in the map editor. After building the FuncGodotMap in Godot, these properties will be added to a Dictionary that gets applied to the generated Node, as long as that Node is a tool script with an exported `func_godot_properties` Dictionary.
@export var class_properties : Dictionary = {}

## Descriptions for previously defined key value pair properties.
@export var class_property_descriptions : Dictionary = {}

## Appearance properties for the map editor. See the [**Valve FGD**](https://developer.valvesoftware.com/wiki/FGD#Entity_Description) and [**TrenchBroom**](https://trenchbroom.github.io/manual/latest/#display-models-for-entities) documentation for more information.
@export var meta_properties : Dictionary = {
	"size": AABB(Vector3(-8, -8, -8), Vector3(8, 8, 8)),
	"color": Color(0.8, 0.8, 0.8)
}

@export_group("Node Generation")

## Node to generate on map build. This can be a built-in Godot class or a GDExtension class. For Point Class entities that use Scene File instantiation leave this blank.
@export var node_class := ""

func build_def_text() -> String:
	# Class prefix
	var res : String = prefix

	# Meta properties
	var base_str = ""
	var meta_props = meta_properties.duplicate()

	for base_class in base_classes:
		if not 'classname' in base_class:
			continue

		base_str += base_class.classname

		if base_class != base_classes.back():
			base_str += ", "

	if base_str != "":
		meta_props['base'] = base_str

	for prop in meta_props:
		if self is FuncGodotFGDSolidClass:
			if prop == "size" or prop == "model":
				continue
		
		var value = meta_props[prop]
		res += " " + prop + "("

		if value is AABB:
			res += "%s %s %s, %s %s %s" % [
				value.position.x,
				value.position.y,
				value.position.z,
				value.size.x,
				value.size.y,
				value.size.z
			]
		elif value is Color:
			res += "%s %s %s" % [
				value.r8,
				value.g8,
				value.b8
			]
		elif value is String:
			res += value

		res += ")"

	res += " = " + classname

	var normalized_description = description.replace("\n", " ").strip_edges()
	if normalized_description != "":
		res += " : \"%s\" " % [normalized_description]

	res += "[" + FuncGodotUtil.newline()

	# Class properties
	for prop in class_properties:
		var value = class_properties[prop]

		var prop_val = null
		var prop_type := ""
		var prop_description: String
		if prop in class_property_descriptions:
			# Optional default value for Choices can be set up as [String, int]
			if value is Dictionary and class_property_descriptions[prop] is Array:
				var prop_arr: Array = class_property_descriptions[prop]
				if prop_arr.size() > 1 and prop_arr[1] is int:
					prop_description = "\"" + prop_arr[0] + "\" : " + str(prop_arr[1])
                else:
                    prop_description = "\"\" : 0"
                    printerr(str(prop) + " has incorrect description format. Should be [String description, int default value].")
			else:
				prop_description = "\"" + class_property_descriptions[prop] + "\""
		else:
			prop_description = "\"\""

		if value is int:
			prop_type = "integer"
			prop_val = str(value)
		elif value is float:
			prop_type = "float"
			prop_val = "\"" + str(value) + "\""
		elif value is String:
			prop_type = "string"
			prop_val = "\"" + value + "\""
		elif value is Vector3:
			prop_type = "string"
			prop_val = "\"%s %s %s\"" % [
				value.x,
				value.y,
				value.z
			]
		elif value is Color:
			prop_type = "color255"
			prop_val = "\"%s %s %s\"" % [
				value.r8,
				value.g8,
				value.b8
			]
		elif value is Dictionary:
			prop_type = "choices"
			prop_val = "[" + "\n"
			for choice in value:
				var choice_val = value[choice]
				prop_val += "\t\t" + str(choice_val) + " : \"" + choice + "\"\n"
			prop_val += "\t]"
		elif value is Array:
			prop_type = "flags"
			prop_val = "[" + "\n"
			for arr_val in value:
				prop_val += "\t\t" + str(arr_val[1]) + " : \"" + str(arr_val[0]) + "\" : " + ("1" if arr_val[2] else "0") + "\n"
			prop_val += "\t]"
		elif value is NodePath:
			prop_type = "target_destination"
		elif value is Object:
			prop_type = "target_source"

		if(prop_val):
			res += "\t"
			res += prop
			res += "("
			res += prop_type
			res += ")"

			if not value is Array:
				if not value is Dictionary or prop_description != "":
					res += " : "
					res += prop_description

			if value is Dictionary or value is Array:
				res += " = "
			else:
				res += " : "

			res += prop_val
			res += FuncGodotUtil.newline()

	res += "]" + FuncGodotUtil.newline()

	return res