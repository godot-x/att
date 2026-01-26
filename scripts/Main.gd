extends Control

const ATT_PLUGIN_NAME = "GodotxATT"
var att = null

@onready var status_label = $VBoxContainer/ScrollContainer/Content/SectionStatus/SectionStatusVBox/StatusLabel
@onready var log_output = $VBoxContainer/ScrollContainer/Content/LogOutput


func log_message(message: String) -> void:
	log_output.text += message + "\n"
	log_output.scroll_vertical = log_output.get_v_scroll_bar().max_value


func dict_to_string(dict: Dictionary) -> String:
	var out := "{\n"
	for key in dict.keys():
		out += "  %s: %s\n" % [key, dict[key]]
	out += "}"
	return out


func update_status_display() -> void:
	if att == null:
		status_label.text = "Plugin not available"
		return

	var status_code = att.get_status()
	var status_string = att.get_status_string()
	status_label.text = "%s (%d)" % [status_string, status_code]


func _ready():
	if Engine.has_singleton(ATT_PLUGIN_NAME):
		att = Engine.get_singleton(ATT_PLUGIN_NAME)
		log_message("Plugin loaded")
		connect_signals()
		update_status_display()
	else:
		log_message("Plugin not found")
		status_label.text = "Plugin not available"


func connect_signals() -> void:
	if att == null:
		return

	att.permission_result.connect(_on_permission_result)
	log_message("Signals connected")


func _on_request_permission_pressed():
	if att == null:
		log_message("Plugin not available")
		return

	att.request_permission()
	log_message("request_permission()")


func _on_get_status_pressed():
	if att == null:
		log_message("Plugin not available")
		return

	var status_code = att.get_status()
	var status_string = att.get_status_string()
	log_message("get_status() = %d" % status_code)
	log_message("get_status_string() = %s" % status_string)
	update_status_display()


func _on_clear_log_pressed():
	log_output.text = ""


func _on_permission_result(data):
	log_message("SIGNAL: permission_result")
	log_message(dict_to_string(data))

	var status: int = data.get("status", -1)

	if status == ATTStatus.AUTHORIZED:
		log_message("Tracking authorized!")
	elif status == ATTStatus.DENIED:
		log_message("Tracking denied")
	elif status == ATTStatus.RESTRICTED:
		log_message("Tracking restricted")
	elif status == ATTStatus.NOT_DETERMINED:
		log_message("Status not determined")

	log_message("Is trackable: %s" % ATTStatus.is_trackable(status))

	update_status_display()
