@tool
class_name SpanningCellContainer extends Container
## This custom container is used as a child of the [SpanningTableContainer] to
## configure cells that spanns over multiple columns and/or rows.
##
## Use the col_span and row_span to have this container span over multiple cells. 
## Combine with expand flag the control will span over the defined columns and rows.
## Setting expand flag for one Cntainer will set the expand flag for the entire
## row or column.


## Number of columns this container should span ower.
@export_range(1,1025) var col_span : int = 1 :
	set(value):
		col_span = value
		var parent = get_parent()
		if parent:
			parent.queue_sort()
			parent.update_minimum_size()
		update_configuration_warnings()


## Number of rows this container should span over.
@export_range(1,1025) var row_span : int = 1 :
	set(value):
		row_span = value
		var parent = get_parent()
		if parent:
			parent.queue_sort()
			parent.update_minimum_size()


# Check the cell configuration to give user feedback about most common errors.
func _get_configuration_warnings():
	var warnings = []
	var parent = get_parent()
	if parent:
		var table = parent as SpanningTableContainer
		if !table:
			warnings.append("Parent should be a SpanningTableContainer.")
		if table and col_span > table.columns:
			warnings.append("This cell dosn't fitt in parent table, as parent colums is less than the column span of this cell!")
	
	return warnings


# Hook into the sort child notification to place the child controls during sorting.
func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()


# Perform the shorting of the children of this control
func _handle_sort_children():
	for child in get_children():
		# Child should be of control type, to be able to adjust positions
		var control_child = child as Control
		if control_child == null:
			continue
		
		# Some more conditions where the child should not be adjusted
		if not control_child.is_visible_in_tree() || control_child.is_set_as_top_level():
			continue
		
		# Child fill the entire area of the cell
		fit_child_in_rect(control_child, Rect2(Vector2(), get_size()))


# Calculate the minimum size for this control
func _get_minimum_size() -> Vector2:
	for child in get_children():
		# Child should be of control type, to be able to adjust positions
		var control_child = child as Control
		if control_child == null:
			continue
		
		# Some more conditions where the child should not be adjusted
		if not control_child.is_visible_in_tree() || control_child.is_set_as_top_level():
			continue
		
		return control_child.get_combined_minimum_size()
	
	return Vector2()
