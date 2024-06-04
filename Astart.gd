extends TileMap

var Astar1 :AStar2D = AStar2D.new()
#控制玩家是否可以移动
var Player_Move:bool = false
var path_node:Path2D


func _ready():
	AStar_init()

#A星初始化
func AStar_init():
	#1、获取tilemap地图上某个图层的坐标数组
	var tilemap_array = self.get_used_cells(0)
	
	#2、把坐标添加为Astar的点
	var index:int = 0
	for i in tilemap_array:
		Astar1.add_point(index,i)
		index += 1
		
	#3、把相邻的点进行连接
	for a in tilemap_array:
		#获取a坐标周围的坐标
		var b_array = get_surrounding_cells(a)
		#遍历a坐标周围的坐标
		for b in b_array:
			#把坐标转换成Astart的点
			var a_points = Astar1.get_closest_point(a)
			var b_points = Astar1.get_closest_point(b)
			#判断这两个点是否存在连接
			if !Astar1.are_points_connected(a_points,b_points):
				#判断这两个点是否重叠（理论上不会重叠，但是不做重叠判断会报错）
				if a_points != b_points:
					#把a点和遍历的这个周围点进行连接
					Astar1.connect_points(a_points,b_points)
					
	#4、设置障碍点（如果有多个碰撞的障碍层，遍历后放到一个数组里面）
	var obstacle_array = self.get_used_cells(1)
	for i in obstacle_array:
		Astar1.set_point_disabled(Astar1.get_closest_point(i),true)


#tilemap寻路。传入起点和终点，返回路径点数组Vector2i
func way(start:Vector2i,end:Vector2i):
	#a_array记录路径点。玩家位置是起点，点击位置是终点
	var a = Astar1.get_closest_point(start)
	var b = Astar1.get_closest_point(end)
	
	var a_array = Astar1.get_point_path(a,b)
	#print("路径："+str(Astar1.get_point_position(b)))
	
	#Line2D画出导航路径
	$"../Line2D".position = Vector2.ZERO
	for i in a_array:
		#$"../Line2D".add_point(map_to_local(Astar1.get_point_position(i))- get_node("/root/Node2D/Player").position)
		$"../Line2D".add_point(map_to_local(i))
	
	#角色移动
	Character_Move(a_array)


#鼠标点击事件
func _input(event):
	#以下两行表示响应的输入为节点内容被左键点击
	if event is InputEventMouseButton and !Player_Move:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			#清除路标
			$"../Line2D".clear_points()
			#点击图块的索引
			var pos_map = local_to_map(event.position)
			#玩家位置
			var player_pos = local_to_map(get_node("/root/Node2D/Player").position)
			
			if player_pos != pos_map:
				way(player_pos,pos_map)

#角色移动,接收移动路径参数
func Character_Move(path_array):
	var curve1:Curve2D = Curve2D.new()
	var path_Fo_node:PathFollow2D = PathFollow2D.new()
	path_node = Path2D.new()
	path_node.name = "Path2D1"
	
	for i in path_array:
		curve1.add_point(map_to_local(i))
	path_Fo_node.loop = false
	path_Fo_node.rotates = false
	path_node.curve = curve1
	
	path_node.add_child(path_Fo_node)
	get_node("/root/Node2D/Player").reparent(path_Fo_node)
	get_node("/root/Node2D").add_child(path_node)
	path_node.get_child(0).get_child(0).position = Vector2.ZERO
	Player_Move = true

#如果角色可以移动，则让它移动
func _process(_delta: float) -> void:
	if Player_Move:
		path_node.get_child(0).progress += 8
		if path_node.get_child(0).progress_ratio >= 1:
			Player_Move = false
			path_node.get_child(0).get_child(0).reparent(get_node("/root/Node2D"))
			get_node("/root/Node2D/Path2D1").queue_free()
