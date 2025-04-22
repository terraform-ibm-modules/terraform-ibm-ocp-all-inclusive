moved {
  from = module.trusted_profile.ibm_iam_trusted_profile_link.link["<trusted-profile-name>-0"]
  to   = module.trusted_profile.ibm_iam_trusted_profile_link.link["<trusted-profile-name>-0-0"]
}
