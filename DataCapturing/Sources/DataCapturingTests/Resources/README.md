
Cyface SDK Test Resource Files
==============================

This directory contains resources providing test data to Cyface SDK unit tests.
The following files are available

- **VXTestData.sqlite**: Databases with data in all the data formats supported by different versions of the app. This should mainly be used to test data migration between app versions.
    V10TestData is rather large and contains several simulated measurements, that could not be transformed successfully with lightweight migration.
    V12TestData is exported from an actual device and waiting for V13 to be released and in need of some test data.
- **serializedFixture.cyf**: A serialized fixture in Cyface Version 2 format (using Protobuf). It contains three valid geographical locations with fixed coordinates at 1.0 and timestamps of 10.000, 10.100 and 10.100. It also contains three accelerations with all values set to 1.0 and timestamps equal to those of the geographical locations. The modality is set to "BICYCLE" and there is a start event at the beginning and a stop event at the end.
- **AltitudeData**: This is example data of a database fork that existed during summer of 2023. In this fork the schema version was V9 but the altitude data already existed in a seperate v11model database. This was to quickly add the altitude data, without compromising older databases and avoiding data migration. The example data is required to test migration of such a setup to the later data schemas, where the altitude data is included with the main database.
