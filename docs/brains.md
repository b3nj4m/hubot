# Brains

Brobbot's brain is pretty cool. It implements a pretty generic key->value store interface, modeled after the redis api.
When a script is loaded, it's given a brain-segment which helps each script operate in a separete key-space.
