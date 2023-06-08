
Cyface SDK Test Resource Files
==============================

This directory contains resources providing test data to Cyface SDK unit tests.
The following files are available

- **VXTestData.sqlite**: Databases with data in all the data formats supported by different versions of the app. This should mainly be used to test data migration between app versions.
    V10TestData is rather large and contains several simulated measurements, that could not be transformed successfully with lightweight migration.
- **serializedFixture.cyf**: A serialized fixture in Cyface Version 2 format (using Protobuf). It contains three valid geographical locations with fixed coordinates at 1.0 and timestamps of 10.000, 10.100 and 10.100. It also contains three accelerations with all values set to 1.0 and timestamps equal to those of the geographical locations. The modality is set to "BICYCLE" and there is a start event at the beginning and a stop event at the end.