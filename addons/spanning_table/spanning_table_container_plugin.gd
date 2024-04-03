@tool
extends EditorPlugin


func _enter_tree():
	# Register the custom containers
	add_custom_type("SpanningTableContainer", "Container", preload("spanning_table_container.gd"), preload("spanning_table_icon.svg"))
	add_custom_type("SpanningCellContainer", "Container", preload("spanning_cell_container.gd"), preload("spanning_cell_icon.svg"))
	pass


func _exit_tree():
	# Unregister the custom containers
	remove_custom_type("SpanningCellContainer")
	remove_custom_type("SpanningTableContainer")
