/**
  Copyright by The HDF Group.                                               *
  Copyright by the Board of Trustees of the University of Illinois.         *
  All rights reserved.                                                      *
                                                                            *
  This file is part of HDF5.  The full HDF5 copyright notice, including     *
  terms governing use, modification, and redistribution, is contained in    *
  the files COPYING and Copyright.html.  COPYING can be found at the root   *
  of the source code distribution tree; Copyright.html can be found at the  *
  root level of an installed copy of the electronic HDF5 document set and   *
  is linked from the top-level documents page.  It can also be found at     *
  http://hdfgroup.org/HDF5/doc/Copyright.html.  If you do not have          *
  access to either file, you may request a copy from help@hdfgroup.org.     *

  Ported by Laeeth Ishaarc 2014 to the D Programming Language
  Use at your own risk!

  This example shows how to read and write string datatypes
  to an attribute.  The program first writes strings to an
  attribute with a dataspace of DIM0, then closes the file.
  Next, it reopens the file, reads back the data, and
  outputs it to the screen.

*/ 

import hdf5.wrap;
import hdf5.bindings.enums;
import hdf5.bindings.api:H5open;
import std.file;
import std.stdio;
import std.exception;
import std.string;
import std.conv;
import std.process;


enum  filename            ="d_examples/h5/h5ex_t_string.h5";
enum  DATASET         ="DS1";
enum  DIM0            =4;
enum  SDIM            =8;

int main(string[] args)
{
    hid_t       file, filetype, memtype, space, dset;
                                            /* Handles */
    herr_t      status;
    hsize_t[1]     dims = [DIM0];
    size_t      sdim;
    char[SDIM][DIM0]        wdata = ["Parting", "is such", "sweet", "sorrow."];
    ubyte[] rdata;
    int         ndims;

    /*
     * Create a new file using the default properties.
     */
    file = H5F.create(filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

    /*
     * Create file and memory datatypes.  For this example we will save
     * the strings as FORTRAN strings, therefore they do not need space
     * for the null terminator in the file.
     */
    filetype = H5T.copy (H5T_FORTRAN_S1);
     H5T.set_size (filetype, SDIM - 1);
    memtype = H5T.copy (H5T_C_S1);
     H5T.set_size (memtype, SDIM);

    /*
     * Create dataspace.  Setting maximum size to NULL sets the maximum
     * size to be the current size.
     */
    space = H5S.create_simple(dims);

    /*
     * Create the dataset and write the string data to it.
     */
    dset = H5D.create2(file, DATASET, filetype, space,H5P_DEFAULT,H5P_DEFAULT, H5P_DEFAULT);
     H5D.write (dset, memtype, H5S_ALL, H5S_ALL, H5P_DEFAULT, cast(ubyte*)wdata.ptr);

    /*
     * Close and release resources.
     */
     H5D.close(dset);
     H5S.close(space);
     H5T.close(filetype);
     H5T.close(memtype);
     H5F.close(file);


    /*
     * Now we begin the read section of this example.  Here we assume
     * the dataset and string have the same name and rank, but can have
     * any size.  Therefore we must allocate a new array to read in
     * data using malloc().
     */

    /*
     * Open file and dataset.
     */
    file = H5F.open(filename, H5F_ACC_RDONLY, H5P_DEFAULT);
    dset = H5D.open2(file, DATASET,H5P_DEFAULT);

    /*
     * Get the datatype and its size.
     */
    filetype = H5D.get_type (dset);
    sdim = H5T.get_size (filetype);
    sdim++;                         /* Make room for null terminator */

    /*
     * Get dataspace and allocate memory for read buffer.  This is a
     * two dimensional dataset so the dynamic allocation must be done
     * in steps.
     */
    space = H5D.get_space (dset);
    ndims = H5S.get_simple_extent_dims(space,dims);

    rdata.length=dims[0]*sdim;
    /*
     * Create the memory datatype.
     */
    memtype = H5T.copy (H5T_C_S1);
     H5T.set_size (memtype, sdim);

    /*
     * Read the data.
     */
     H5D.read (dset, memtype, H5S_ALL, H5S_ALL, H5P_DEFAULT, cast(ubyte*)rdata.ptr);

    /*
     * Output the data to the screen.
     */
    foreach(i;0..dims[0])
        writefln("%s[%d]: %s", DATASET, i, ZtoString(cast(char*)(&rdata[i*sdim])));

    writefln("%s",findAttributes(file));
    writefln("%s",findAttributes(dset));
    writefln("%s",findLinks(file));
    writefln("%s",dataSpaceContents(rdata,filetype,space));
    writefln("file:%s",objectList(file));
    writefln("dset:%s",objectList(dset));
    //writefln("%s",propertyList(H5P_DATATYPE_CREATE_DEFAULT));
    /*
     * Close and release resources.
     */
     H5D.close (dset);
     H5S.close (space);
     H5T.close (filetype);
     H5T.close (memtype);
     H5F.close (file);

    return 0;
}


