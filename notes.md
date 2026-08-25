In short, theres two programs

LibraryBasedProgram uses the library to correlate the magnetic field readings from the helmholtz coil with the output current.
The output of the librarybasedprogram has a magnetic field column, that column is automatically generated based off of the correlation between the magnetic field vs the current. Do not use this column when doing onboard measurements, as it is only valid when doing measurements on the helmholtz coil.

MagneticStation uses the gaussmeter to obtain the actual magnetic fields, and then compared with the current output on the helmholtz coil.

View the program's updates, and the final structure of the program in this repository
https://github.com/200dollarbill/sourcemetermeasurement

Switch to the 'compiled' branch to get the most concise result, without all the junk data and old measurements. Get the 'main' branch to get all the old stuff, which includes all the measurements, 

- Daffa, TEEP 2026
