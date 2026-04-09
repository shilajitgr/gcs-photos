package models

import "time"

// Photo represents photo metadata stored in Firestore and synced to client SQLite.
type Photo struct {
	// Core identifiers
	ImageUID string `json:"imageUID" firestore:"imageUID"`
	ExifKey  string `json:"exifKey" firestore:"exifKey"`
	UserID   string `json:"userID" firestore:"userID"`

	// File info
	FilePathGCS string `json:"filePathGCS" firestore:"filePathGCS"`
	FileName    string `json:"fileName" firestore:"fileName"`
	FileSize    int64  `json:"fileSize" firestore:"fileSize"`
	MimeType    string `json:"mimeType" firestore:"mimeType"`
	Width       int    `json:"width" firestore:"width"`
	Height      int    `json:"height" firestore:"height"`

	// EXIF data
	DateTaken    *time.Time `json:"dateTaken,omitempty" firestore:"dateTaken,omitempty"`
	CameraMake   string     `json:"cameraMake,omitempty" firestore:"cameraMake,omitempty"`
	CameraModel  string     `json:"cameraModel,omitempty" firestore:"cameraModel,omitempty"`
	ISO          int        `json:"iso,omitempty" firestore:"iso,omitempty"`
	Aperture     string     `json:"aperture,omitempty" firestore:"aperture,omitempty"`
	ShutterSpeed string     `json:"shutterSpeed,omitempty" firestore:"shutterSpeed,omitempty"`
	FocalLength  string     `json:"focalLength,omitempty" firestore:"focalLength,omitempty"`
	Latitude     float64    `json:"latitude,omitempty" firestore:"latitude,omitempty"`
	Longitude    float64    `json:"longitude,omitempty" firestore:"longitude,omitempty"`

	// Thumbnails (content-hash-based URLs)
	BlurHash     string `json:"blurHash,omitempty" firestore:"blurHash,omitempty"`
	ThumbSmHash  string `json:"thumbSmHash,omitempty" firestore:"thumbSmHash,omitempty"`
	ThumbMdHash  string `json:"thumbMdHash,omitempty" firestore:"thumbMdHash,omitempty"`
	ThumbLgHash  string `json:"thumbLgHash,omitempty" firestore:"thumbLgHash,omitempty"`

	// Storage lifecycle
	StorageClass  string `json:"storageClass,omitempty" firestore:"storageClass,omitempty"`
	LifecycleRule string `json:"lifecycleRule,omitempty" firestore:"lifecycleRule,omitempty"`

	// Sync metadata
	FirestoreDocID string     `json:"firestoreDocID" firestore:"firestoreDocID"`
	LastSyncedAt   *time.Time `json:"lastSyncedAt,omitempty" firestore:"lastSyncedAt,omitempty"`
	SyncVersion    int64      `json:"syncVersion" firestore:"syncVersion"`

	// Device info
	BackupStatus string `json:"backupStatus" firestore:"backupStatus"`
	DeviceOrigin string `json:"deviceOrigin,omitempty" firestore:"deviceOrigin,omitempty"`
}
