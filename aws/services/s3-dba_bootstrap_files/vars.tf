variable force_destroy {
    type = bool
    description = "Allows the bucket to be destroyed by destroying all
objects in the bucket.  This should be set to false unless wanting to force
terminate.   Must apply the change before a destroy"
    default = false
}