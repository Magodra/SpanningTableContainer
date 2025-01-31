@tool
class_name SpanningTableContainer extends Container
## This custom container organize childs in a table with spanning cells.
##
## Child controls of the [SpanningCellContainer] type can be configured with a 
## row span and clumn span to allow cells to span over multiple
## rows and columns.
##
## The cells are layed out from the upper right starting by filling inn columns in 
## the upper row staring from the first child of the SpanningTableContainer.
## If no more cells are avilable the first cell on the next row will
## be tried. The first location that fitt the entire control will be selected. 
##
## 


## The number of columsn in the table.
@export var columns : int = 1 :
	set(new_columns):
		if columns == new_columns:
			return
		
		columns = new_columns
		
		queue_sort()
		update_minimum_size()

# @TODO Fix this with some real theam override consants. Since this isn't supported by GDScript per 4.2.1 use som exports to simulate...
@export_group("Theme Override Constants","theme_")
## [color=Yellow]Note! This should have been an Theam override, but that is currently
## not supported to create from GDscript. So for now we use an ordinary property.[/color][br]
## This "theme override" represents the spacing between rows.
## @experimental
@export_range(0,1024) var theme_h_separation = 5
## [color=Yellow]Note! This should have been an Theam override, but that is currently
## not supported to create from GDscript. So for now we use an ordinary property.[/color][br]
## This "theme override" represents the spacing"res://README.md" between coloumns.
## @experimental
@export_range(0,1024) var theme_v_separation = 5
@export_group("")


# Hook into the sort child notification to place the child controls during sorting.
func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()


func _occupied(occupied, index, col_span, row_span) -> bool:
	for col_count in range(col_span):
		for row_count in range(row_span):
			if occupied.has(index + col_count + row_count*columns):
				return true
	return false

func _calculate_layout( col_minw : Dictionary, row_minh : Dictionary,  col_expanded : Dictionary, row_expanded : Dictionary, child_array : Array, layout : Dictionary ):
	var occupied : Dictionary # Map of occupied cells, mapped by index.
	
	################################ 1st Stage #################################
	
	# Compute the per-column/per-row data.
	var valid_controls_index = 0
	#occupied.clear()
	for child in get_children():
		# Child should be of control type, to be able to adjust positions
		var control_child = child as Control
		if control_child == null:
			continue
		
		# Some more conditions where the child should not be adjusted
		if not control_child.is_visible_in_tree() || control_child.is_set_as_top_level():
			continue
		
		var spanning_cell = control_child as SpanningCellContainer
		
		var col_span : int = 1
		var row_span : int = 1
		if spanning_cell:
			col_span = spanning_cell.col_span
			row_span = spanning_cell.row_span
		
		# Check if cell is occupied, and find next free
		while _occupied(occupied,valid_controls_index, col_span, row_span):
			valid_controls_index += 1
		
		var row : int = valid_controls_index / columns
		var col : int = valid_controls_index % columns
		
		
		child_array.append({"child": child, "row": row, "col": col, "col_span": col_span, "row_span": row_span})
		
		if spanning_cell:
			for cn in range(col_span):
				for rn in range(row_span):
					if col + cn < columns:
						occupied[col+cn+(row+rn)*columns] = spanning_cell
			
			# In case spannnig cell the valid_control_index may need to be pusehd forward
			while occupied.has(valid_controls_index):
				valid_controls_index += 1
		else:
			occupied[col + row*columns] = control_child
			valid_controls_index += 1
		
		
		var ms : Vector2 = control_child.get_combined_minimum_size()
		
		for cn in col_span:
			if col+cn <= columns:
				if col_minw.has(col+cn):
					col_minw[col+cn] = maxi(col_minw[col+cn], ceili(ms.x/col_span))
				else:
					col_minw[col+cn] = ceili(ms.x/col_span)
				
				if control_child.get_h_size_flags() & SIZE_EXPAND:
					col_expanded[col+cn] = true
		
		for rn in row_span:
			if row_minh.has(row+rn):
				row_minh[row+rn] = maxi(row_minh[row+rn], ceili(ms.y/row_span))
			else:
				row_minh[row+rn] = ceili(ms.y/row_span)
			
			if control_child.get_v_size_flags() & SIZE_EXPAND:
				row_expanded[row+rn] = true
	
	# Consider all empty columns expanded.
	while valid_controls_index < columns:
		col_expanded[valid_controls_index] = true
		col_minw[valid_controls_index] = 0
		valid_controls_index += 1
	
	# Check if there are no, rows, define min height.
	if row_minh.size() == 0:
		row_minh[0] = 0
	
	layout["max_col"] = mini(valid_controls_index, columns)
	layout["max_row"] = row_minh.size()
	
	# Debug prints used during debug of the calculate_layout function.
	#print("occupied", occupied)
	#print("col_minw: ", col_minw)
	#print("row_minh: ", row_minh)
	#print("col_expanded: ", col_expanded)
	#print("row_expanded: ", row_expanded)
	#print("layout", layout)
	#print("child_array", child_array)


# Perform the shorting of the children of this control
func _handle_sort_children():
	
	var col_minw : Dictionary # Max of min_width of all controls in each col (indexed by col).
	var row_minh : Dictionary # Max of min_height of all controls in each row (indexed by row).
	var col_expanded : Dictionary # Columns which have the SIZE_EXPAND flag set.
	var row_expanded : Dictionary # Rows which have the SIZE_EXPAND flag set.
	var layout : Dictionary # Table layout with max_col and max_row information
	var child_array : Array # Array of child elements and positions/size of each control.
	
	################################# 1st Stage #################################
	# Calcuate the layout of the table.
	
	_calculate_layout(col_minw, row_minh, col_expanded, row_expanded, child_array, layout)
	var max_col : int = layout.max_col
	var max_row : int = layout.max_row
	
	################################ 2nd Stage #################################
	# Tune colum width and row heights.
	
	# Evaluate the remaining space for expanded columns/rows.
	var remaining_space : Vector2i = get_size();
	for key in col_minw:
		var value = col_minw[key]
		if !col_expanded.has(key):
			remaining_space.x -= value;
		
	for key in row_minh:
		var value = row_minh[key]
		if !row_expanded.has(key):
			remaining_space.y -= value;
	
	remaining_space.y -= theme_v_separation * maxi(max_row - 1, 0)
	remaining_space.x -= theme_h_separation * maxi(max_col - 1, 0)
	
	var can_fit : bool = false
	while !can_fit && col_expanded.size() > 0:
		# Check if all minwidth constraints are OK if we use the remaining space.
		can_fit = true
		var max_index : int = col_expanded.keys().front()
		for E in col_expanded:
			if col_minw[E] > col_minw[max_index]:
				max_index = E
			if can_fit && (remaining_space.x / col_expanded.size()) < col_minw[E]:
				can_fit = false
		
		# If not, the column with maximum minwidth is not expanded.
		if !can_fit:
			col_expanded.erase(max_index);
			remaining_space.x -= col_minw[max_index];
	
	can_fit = false
	while !can_fit && row_expanded.size() > 0:
		# Check if all minheight constraints are OK if we use the remaining space.
		can_fit = true
		var max_index : int = row_expanded.keys().front()#->get();
		for E in row_expanded:
			if row_minh[E] > row_minh[max_index]:
				max_index = E
			if can_fit && (remaining_space.y / row_expanded.size()) < row_minh[E]:
				can_fit = false
		
		# If not, the row with maximum minheight is not expanded.
		if !can_fit:
			row_expanded.erase(max_index)
			remaining_space.y -= row_minh[max_index]
	
	# Finally, fit the nodes.
	var col_remaining_pixel :int = 0
	var col_expand : int = 0
	if col_expanded.size() > 0:
		col_expand = remaining_space.x / col_expanded.size()
		col_remaining_pixel = remaining_space.x - col_expanded.size() * col_expand
	
	var row_remaining_pixel : int = 0
	var row_expand : int = 0
	if row_expanded.size() > 0:
		row_expand = remaining_space.y / row_expanded.size()
		row_remaining_pixel = remaining_space.y - row_expanded.size() * row_expand
	
	# Calculate the with of rows and columns and rows and columsn that receive the remaining pixel 
	var rtl : bool = is_layout_rtl()
	var col_width : Array[int]
	col_width.resize(max_col)
	var col_pos : Array[int]
	col_pos.resize(max_col)
	var curr_col_pos : int = 0
	if rtl:
		curr_col_pos = get_size().x
	for col in range (max_col):
		col_pos[col] = curr_col_pos 
		if col_expanded.has(col):
			col_width[col] = col_expand
			if col_remaining_pixel > 0:
				col_remaining_pixel -= 1
				col_width[col] += 1
		else:
			col_width[col] = col_minw[col]
		if rtl:
			curr_col_pos -= col_width[col]
			col_pos[col] -= col_width[col] - theme_h_separation
		else:
			curr_col_pos += col_width[col] + theme_h_separation
	
	var row_height : Array[int]
	row_height.resize(max_row)
	var row_pos : Array[int]
	row_pos.resize(max_row)
	var curr_row_pos : int = 0
	for row in range (max_row):
		row_pos[row] = curr_row_pos
		if row_expanded.has(row):
			row_height[row] = row_expand
			if row_remaining_pixel > 0:
				row_remaining_pixel -= 1
				row_height[row] += 1
		else:
			row_height[row] = row_minh[row]
		curr_row_pos += row_height[row] + theme_v_separation
	
	# Debug prints used to debug the spanning table with calculations
	#print("col_width: ", col_width)
	#print("col_pos: ", col_pos)
	#print("row_height: ", row_height)
	#print("row_pos: ", row_pos)
	
	################################ 3nd Stage #################################
	# Set the size and position of each child control.
	
	for child_entry in child_array:
		var row : int = child_entry.row
		var col : int = child_entry.col
		var col_span : int = child_entry.col_span
		var row_span : int = child_entry.row_span
		
		var p = Vector2i(col_pos[col], row_pos[row])
		var cw : int = 0
		var rh : int = 0
		for n in range(col_span):
			# TODO : Check for out of bounds, this should be handle before in stage 1. If all controls are within the column limits!!!
			if col+n < columns:
				cw += col_width[col+n]
		for n in range(row_span):
			rh += row_height[row+n]
		var s = Vector2i(cw + theme_h_separation*(col_span-1), rh + theme_v_separation*(row_span-1) )
		fit_child_in_rect(child_entry.child, Rect2(p, s))


# Calculate the minimum size for this control
func _get_minimum_size() -> Vector2:
	
	var col_minw : Dictionary # Max of min_width of all controls in each col (indexed by col).
	var row_minh : Dictionary # Max of min_height of all controls in each row (indexed by row).
	var col_expanded : Dictionary # Columns which have the SIZE_EXPAND flag set.
	var row_expanded : Dictionary # Rows which have the SIZE_EXPAND flag set.
	var layout : Dictionary # Table layout with max_col and max_row information
	var child_array : Array # Array of child elements and positions/size of each control.
	
	################################# 1st Stage #################################
	# Calcuate the layout of the table.
	
	_calculate_layout(col_minw, row_minh, col_expanded, row_expanded, child_array, layout)
	var max_col : int = layout.max_col
	var max_row : int = layout.max_row
	
	################################# 2nd Stage #################################
	# Calucate the minimum size based on the calculated layout of the table.
	
	var min_size : Vector2 = Vector2(theme_h_separation*(max_col-1),theme_v_separation*(max_row-1))
	for w in col_minw.values():
		min_size.x += w
	for h in row_minh.values():
		min_size.y += h
	
	return min_size
