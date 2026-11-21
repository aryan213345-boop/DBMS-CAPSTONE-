// ============================================================
// PROJECT 1 - CO4 NoSQL Extension
// MongoDB Collection for Maintenance Reports & Equipment Metadata
// ============================================================

// Use: mongosh or MongoDB Compass / Atlas

// 1. Create Database & Collection
use smart_campus_nosql;

// 2. Insert sample maintenance / equipment documents
// (semi-structured data that does not fit cleanly in relational tables)

db.maintenance_reports.insertMany([
  {
    resource_code: "3DP-01",
    resource_name: "Ultimaker 3D Printer",
    report_date: ISODate("2024-10-01T10:00:00Z"),
    reported_by: "Suresh Nair",
    issue: {
      type: "Nozzle Clogging",
      severity: "Medium",
      description: "Filament not extruding properly after 4 hours of continuous use",
      photos: ["photo1.jpg", "photo2.jpg"],
      tags: ["hardware", "print-quality", "recurring"]
    },
    actions_taken: [
      { step: 1, action: "Cleaned nozzle with cold-pull", timestamp: ISODate("2024-10-01T11:30:00Z") },
      { step: 2, action: "Replaced PTFE tube", timestamp: ISODate("2024-10-01T14:00:00Z") }
    ],
    parts_used: [
      { part: "PTFE Tube 4mm", quantity: 1, cost: 350 }
    ],
    status: "In Progress",
    estimated_completion: ISODate("2024-10-03T17:00:00Z"),
    downtime_hours: 18
  },
  {
    resource_code: "PC-ECE1-01",
    resource_name: "Workstation ECE",
    report_date: ISODate("2024-09-20T09:00:00Z"),
    reported_by: "Lab Coordinator",
    issue: {
      type: "Hard Disk Failure",
      severity: "High",
      description: "System not booting, SMART status failed",
      tags: ["storage", "critical", "data-recovery"]
    },
    actions_taken: [
      { step: 1, action: "Diagnosed with diagnostics tool", timestamp: ISODate("2024-09-20T10:00:00Z") },
      { step: 2, action: "Replaced HDD with SSD 512GB", timestamp: ISODate("2024-09-22T15:00:00Z") },
      { step: 3, action: "Reinstalled OS and drivers", timestamp: ISODate("2024-09-23T11:00:00Z") }
    ],
    parts_used: [
      { part: "Samsung 512GB SSD", quantity: 1, cost: 4200 }
    ],
    status: "Completed",
    actual_completion: ISODate("2024-09-25T17:00:00Z"),
    downtime_hours: 48,
    final_cost: 4500
  },
  {
    resource_code: "IOT-KIT-01",
    resource_name: "Arduino Starter Kit 01",
    report_date: ISODate("2024-09-15T14:00:00Z"),
    reported_by: "Student",
    issue: {
      type: "Missing Components",
      severity: "Low",
      description: "Several jumper wires and one ultrasonic sensor missing",
      tags: ["inventory", "kit"]
    },
    status: "Completed",
    actions_taken: [
      { step: 1, action: "Replaced missing items from inventory", timestamp: ISODate("2024-09-16T10:00:00Z") }
    ],
    downtime_hours: 0
  }
]);

// 3. Equipment Metadata (flexible document)
db.equipment_metadata.insertMany([
  {
    resource_code: "3DP-01",
    manufacturer: "Ultimaker",
    model: "S3",
    serial_number: "UM3S-2023-8841",
    firmware_version: "5.2.11",
    specifications: {
      build_volume: "230 x 190 x 200 mm",
      layer_resolution: "20-200 micron",
      materials: ["PLA", "ABS", "PETG", "TPU"],
      connectivity: ["WiFi", "USB", "Ethernet"]
    },
    calibration_history: [
      { date: ISODate("2024-01-15"), by: "Technician A", notes: "Bed leveling completed" },
      { date: ISODate("2024-06-20"), by: "Technician B", notes: "Extruder calibration" }
    ],
    documents: [
      { type: "Manual", url: "/docs/ultimaker_s3_manual.pdf" },
      { type: "Warranty", expiry: ISODate("2026-09-20") }
    ]
  },
  {
    resource_code: "PROJ-SH101",
    manufacturer: "Epson",
    model: "EB-2250U",
    serial_number: "EPS-2022-4412",
    specifications: {
      brightness: "5000 lumens",
      resolution: "WUXGA",
      connectivity: ["HDMI", "VGA", "Wireless"]
    },
    lamp_hours: 1250,
    last_filter_clean: ISODate("2024-08-10")
  }
]);

// 4. Useful Aggregations (required for CO4)

// Aggregation 1: Total downtime and cost by resource

db.maintenance_reports.aggregate([
  {
    $group: {
      _id: "$resource_code",

      total_downtime_hours: {
        $sum: "$downtime_hours"
      },

      total_cost: {
        $sum: {
          $ifNull: [
            "$final_cost",
            {
              $reduce: {
                input: { $ifNull: ["$parts_used", []] },
                initialValue: 0,
                in: {
                  $add: [
                    "$$value",
                    {
                      $multiply: [
                        "$$this.quantity",
                        "$$this.cost"
                      ]
                    }
                  ]
                }
              }
            }
          ]
        }
      },

      report_count: {
        $sum: 1
      },

      last_report: {
        $max: "$report_date"
      }
    }
  },
  {
    $sort: {
      total_downtime_hours: -1
    }
  }
]);

// Aggregation 2: Issues by severity and type
db.maintenance_reports.aggregate([
  {
    $group: {
      _id: {
        severity: "$issue.severity",
        type: "$issue.type"
      },
      count: { $sum: 1 },
      avg_downtime: { $avg: "$downtime_hours" }
    }
  },
  { $sort: { count: -1 } }
]);

// Aggregation 3: Monthly maintenance trend
db.maintenance_reports.aggregate([
  {
    $group: {
      _id: {
        year: { $year: "$report_date" },
        month: { $month: "$report_date" }
      },
      reports: { $sum: 1 },
      total_downtime: { $sum: "$downtime_hours" }
    }
  },
  { $sort: { "_id.year": 1, "_id.month": 1 } }
]);

// 5. Justification (to be included in report)
/*
Why MongoDB for this part?
- Maintenance reports have variable structure (different actions, parts, photos, tags).
- Equipment metadata has nested arrays and evolving fields (firmware, calibration history).
- Document model allows flexible querying and aggregation without rigid schema changes.
- Core transactional data (bookings, approvals, usage) remains in relational DB for ACID guarantees.
- Hybrid approach demonstrates understanding of polyglot persistence (CO4).
*/
