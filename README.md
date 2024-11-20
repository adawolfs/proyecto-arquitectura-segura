# Proyecto para la creacion de arquitectura segura

## Requisitos
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Google Cloud Platform](https://cloud.google.com/)
- [Terraform](https://www.terraform.io/downloads.html)

### Login con Google Cloud SDK
```bash
gcloud auth login
```

### Crear un proyecto en GCP
Es necesario reemplazar el nombre del proyecto
```bash
gcloud projects create <PROJECT_ID>
```

### Configurar el auth application-default
```bash
cloud auth application-default login
```

### Crear ssh-key
```bash
ssh-keygen -t rsa -f ./id_rsa -C "proyecto"
```

### Crear variables de entorno
Es necesario reemplazar el nombre del proyecto
```bash
export TF_VAR_project_id=<PROJECT_ID>
```

### Inicializar Terraform
```bash
terraform init
```

### Crear infraestructura
```bash
terraform apply
```

### Destruir infraestructura
```bash
terraform destroy
```


