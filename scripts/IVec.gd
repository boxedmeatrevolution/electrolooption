class IVec:
	var x: int
	var y: int

	func _init(x: int, y: int):
		self.x = x
		self.y = y
		
	func eq(other: IVec) -> bool:
		return x == other.x and y == other.y
		
	func copy() -> IVec:
		return IVec.new(x, y)
		
	func minus(other: IVec) -> IVec:
		return IVec.new(x - other.x, y - other.y)
