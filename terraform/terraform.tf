terraform {
  cloud {
    organization = "leandro-soares-org"
    workspaces {
      name = "laboratoriok3s"
    }
  }
}
