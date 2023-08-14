terraform {
  backend "oci" {
    bucket                     = "my-terraform-state-bucket"
    compartment_ocid           = "YOUR_COMPARTMENT_OCID"
    tenancy_ocid               = "YOUR_TENANCY_OCID"
    user_ocid                  = "YOUR_USER_OCID"
    fingerprint                = "YOUR_FINGERPRINT"
    private_key_path           = "path_to_your_private_key.pem"
    region                     = "us-ashburn-1"
    disable_auto_retries       = false
    retry_max_attempts         = 0
    retry_duration_seconds     = 10
    state_lock                 = true
    state_lock_wait_time       = "0s"
    state_lock_wait_max_retries = 0
  }
}