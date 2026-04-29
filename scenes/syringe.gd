extends StaticBody3D

## How much stamina this syringe restores when used.
@export var stamina_restore : float = 35.0

func interact(character: CharacterBody3D) -> void:
	character.stamina = min(character.max_stamina, character.stamina + stamina_restore)
	queue_free()
