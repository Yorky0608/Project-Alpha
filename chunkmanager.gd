extends Node
class_name ChunkManager

var chunk_states := {}  # Dictionary: { chunk_id:String : ChunkState }

func get_state(chunk_id: String) -> Chunkstate:
	if not chunk_states.has(chunk_id):
		var state = Chunkstate.new()
		state.chunk_id = chunk_id
		chunk_states[chunk_id] = state
	return chunk_states[chunk_id]

func set_state(chunk_id: String, state: Chunkstate):
	chunk_states[chunk_id] = state
