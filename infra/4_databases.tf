resource "aws_db_subnet_group" "db_subnets" {
  name       = "mexp-db-subnet-group"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags       = var.tags_base
}

# Base de Datos 1: Myxperiences
resource "aws_db_instance" "postgres_myxperiences" {
  # identifier = "mexp-postgres-myxperiences" 👈 BORRA O COMENTA ESTA LÍNEA
  allocated_storage      = 20
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  db_name                = "myxperiencesdb"
  username               = var.db_user_myxperiences
  password               = var.db_password_myxperiences
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = merge(var.tags_base, {
    Name = "mexp-postgres-myxperiences"
    app  = "xperiences"
  })
}

# Base de Datos 2: Lanapp
resource "aws_db_instance" "postgres_awsp" {
  # identifier = "mexp-postgres-lanapp" 👈 BORRA O COMENTA ESTA LÍNEA
  allocated_storage      = 20
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  db_name                = "lanappdb"
  username               = var.db_user_lanapp
  password               = var.db_password_lanapp
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  #   publicly_accessible    = true

  tags = merge(var.tags_base, {
    Name = "mexp-postgres-lanapp"
    app  = "awsp"
  })
}

# Base de Datos 3: Administración
resource "aws_db_instance" "postgres_admin" {
  # identifier = "mexp-postgres-admin" 👈 BORRA O COMENTA ESTA LÍNEA
  allocated_storage      = 20
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  db_name                = "admindb"
  username               = var.db_user_admin
  password               = var.db_password_admin
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = merge(var.tags_base, {
    Name = "mexp-postgres-admin"
    app  = "admin"
  })
}
