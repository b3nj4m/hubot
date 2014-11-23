class BrainSegment
  constructor: (@brain, @prefix = '') ->
    @get = @brain.get.bind(@brain, prefix)
    @set = @brain.set.bind(@brain, prefix)

