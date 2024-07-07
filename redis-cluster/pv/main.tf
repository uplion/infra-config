resource "kubernetes_persistent_volume" "pv" {
  count = var.pv_count

  metadata {
    name   = "${var.pv_name_prefix}-pv-${count.index + 1}"
    labels = var.pv_labels
  }

  spec {
    storage_class_name = var.storage_class

    capacity = {
      storage = var.storage_size # 设置 PV 的存储容量
    }

    access_modes = ["ReadWriteOnce"] # 设置访问模式
    persistent_volume_source {
      host_path = {
        path = "${var.host_path}_${count.index + 1}"
      }
    }
    persistent_volume_reclaim_policy = "Retain" # 设置回收策略
    claim_ref = {
      name      = "pvc-${count.index + 1}"
      namespace = "default"
    }
  }
}
