class IVec:
	var x: int
	var y: int

	func _init(x: int, y: int):
		self.x = x
		self.y = y
		
	func eq(other) -> bool:
		return x == other.x and y == other.y
		
	func copy():
		return Utility._copy_vec(self)
		
	func minus(other):
		return Utility._minus_vec(self, other)
		
	func add(other):
		return Utility._add_vec(self, other)
