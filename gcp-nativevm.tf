# create test instance - native vnet


# bootstrap script to install apache on linux instance
data "template_file" "linux-metadata" {
template = <<EOF
sudo apt-get update; 
sudo apt-get install -y apache2;
sudo systemctl start apache2;
sudo systemctl enable apache2;
EOF
}

# Create test VM instances
resource "google_compute_instance" "vm-native40" {
  project      = var.project
  name         = "${var.network1_name}-subnet1-gcpvm"
  machine_type = "f1-micro"
  #zone         = "europe-west4-a"
  zone        = "europe-west2-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20230324"
    }
  }

  metadata_startup_script = data.template_file.linux-metadata.rendered           # points to 'data template block'
  #metadata = {
  #  startup-script = file("${path.module}/bootstrap.sh")
  #}

  network_interface {
    network    = google_compute_network.network1.id
    subnetwork = "https://www.googleapis.com/compute/v1/projects/${var.project}/regions/subnetworks/${google_compute_subnetwork.network1_subnet1.name}"
    #subnetwork = "https://www.googleapis.com/compute/v1/projects/${var.project}/regions/subnetworks/${google_compute_subnetwork.network1_subnet2.name}"
    access_config {} //ephemeral IP
  }

  tags = ["allow-ssh", "allow-icmp", "allow-http"]                #  firewall rules will associate with this
  depends_on = [ google_compute_subnetwork.network1_subnet1 ]
  lifecycle {
    ignore_changes = all
  }
}


# Firewall rule to allow ssh
resource "google_compute_firewall" "allow_sshnative" {
  project  = var.project
  name     = "${google_compute_subnetwork.network1_subnet1.name}-allow-ssh"
  network  = google_compute_network.network1.id


  allow {
    protocol = "tcp"
    ports    = ["22"]
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "allow_icmpnative" {
  project  = var.project
  name     = "${google_compute_subnetwork.network1_subnet1.name}-allow-icmp"
  network  = google_compute_network.network1.id


  allow {
    protocol = "icmp"
  }


  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  target_tags   = ["allow-icmp"]
}

resource "google_compute_firewall" "allow_httpnative" {
  project  = var.project
  name     = "${google_compute_subnetwork.network1_subnet1.name}-allow-http"
  network  = google_compute_network.network1.id



  allow {
    protocol = "tcp"
    ports    = ["80"]
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
}



# test vm nativevpc30
resource "google_compute_instance" "vm-native30" {
  project      = var.project
  name         = "${var.network2_name}-subnet2-gcpvm"
  machine_type = "f1-micro"
  zone         = "europe-west4-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20230324"
    }
  }

  metadata_startup_script = data.template_file.linux-metadata.rendered           # points to 'data template block'
  #metadata = {
  #  startup-script = file("${path.module}/bootstrap.sh")
  #}

  network_interface {
    network    = google_compute_network.network2.id
    subnetwork = "https://www.googleapis.com/compute/v1/projects/${var.project}/regions/subnetworks/${google_compute_subnetwork.network2_subnet2.name}"
    access_config {} //ephemeral IP
  }

  tags = ["allow-ssh", "allow-icmp", "allow-http"]                #  firewall rules will associate with this
  depends_on = [ google_compute_subnetwork.network2_subnet2 ]
  lifecycle {
    ignore_changes = all
  }
}


# Firewall rule to allow ssh
resource "google_compute_firewall" "allow_sshnative30" {
  project  = var.project
  name     = "${google_compute_subnetwork.network2_subnet2.name}-allow-ssh"
  network  = google_compute_network.network2.id


  allow {
    protocol = "tcp"
    ports    = ["22"]
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "allow_icmpnative30" {
  project  = var.project
  name     = "${google_compute_subnetwork.network2_subnet2.name}-allow-icmp"
  network  = google_compute_network.network2.id


  allow {
    protocol = "icmp"
  }


  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  target_tags   = ["allow-icmp"]
}

resource "google_compute_firewall" "allow_httpnative30" {
  project  = var.project
  name     = "${google_compute_subnetwork.network2_subnet2.name}-allow-http"
  network  = google_compute_network.network2.id



  allow {
    protocol = "tcp"
    ports    = ["80"]
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
}


