variable kms_keys {
    type = map(object({
        key_description = string
        role_permissions= map(string)
        service_permissions= optional(map(string),null)
    }))
    description = "a map of kms keys"
    /*
        "key_alias" = {
            key_description = 'my keys description goes here'
            role_permissions = {
                'role_arn' = 'role_permission'
            }
            service_permissions = {
                'role_arn' = 'role_permission'
            }
        }
    */
}