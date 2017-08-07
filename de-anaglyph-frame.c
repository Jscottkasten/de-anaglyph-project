/*
###################################################################################
# Copyright (C) 2015, 2016, 2017 by UVS Innovations Corporation.                  #
# All rights reserved.                                                            #
#                                                                                 #
# Redistribution and use in source and binary forms, with or without              #
# modification, are permitted provided that the following conditions are met:     #
#                                                                                 #
# 1. Redistributions of source code must retain the above copyright notice, this  #
#    list of conditions and the following disclaimer.                             #
# 2. Redistributions in binary form must reproduce the above copyright notice,    #
#    this list of conditions and the following disclaimer in the documentation    #
#    and/or other materials provided with the distribution.                       #
#                                                                                 #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND #
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED   #
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          #
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR #
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES  #
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    #
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND     #
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT      #
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS   #
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                    #
#                                                                                 #
###################################################################################
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

char USAGE_STRING[] = "USAGE: img-src | de-anaglyph <720p|1080p|1536> | img-sink\n";


int main(int argc, char *argv[])
{
    int size_x, size_y, nbytes_in, nbytes_out;
    unsigned char *in_buff, *out_buff;

    // Process arguments.
    if (argc != 2)
    {
        fprintf(stderr, USAGE_STRING);
        return (1);
    }
    else
    {
        if (strncmp(argv[1], "720p", 4) == 0)
        {
            size_x = 1280;
            size_y =  720;
        }
        else if (strncmp(argv[1], "1080p", 5) == 0)
        {
             size_x = 1920;
             size_y = 1080;
        }
        else if (strncmp(argv[1], "1536", 4) == 0)
        {
             size_x = 2048;
             size_y = 1536;
        }
        else
        {
            fprintf(stderr, USAGE_STRING);
            return (1);
        }
    }

    // Allocate memory.
    nbytes_in  = (size_x * size_y) * 3;
    in_buff    = (unsigned char *) malloc(nbytes_in);

    nbytes_out = (size_x * 2) * size_y;
    out_buff   = (unsigned char *) malloc(nbytes_out);

    if ((in_buff == NULL) || (out_buff == NULL))
    {
         fprintf(stderr, "%s: Failed to allocate memory.", argv[0]);
         return (errno);
    }

    // Read it in.
    {
        int  bytes_read, bytes_to_read;
        unsigned char *s;

        bytes_to_read = nbytes_in;
        s = in_buff;
        while (bytes_to_read > 0)
        {
            bytes_read = read(fileno(stdin), s, bytes_to_read);

            if (bytes_read <= 0)
            {
                fprintf(stderr, "%s: Error reading input data.\n", argv[0]);
                return (errno);
            }

            bytes_to_read -= bytes_read;
            s += bytes_read;
        }
    }

    // Process it.
    {
        int    x, y, src_idx, dst_idx;
        double cross  = (double) -0.05,
               l_corr = ((double) 0.587 + (double) 0.114) * (double) 0.642,
               r_corr = (double) 0.750;
        double r, g, b, l;

        // Left.
        for (y = 0; y < size_y; y++)
        {
            for (x = 0; x < size_x; x++)
            {
                src_idx = ((y * size_x) + x) * 3;
                dst_idx = ((y * size_x * 2) + x);

                r       = (double) in_buff[src_idx];
                g       = (double) in_buff[src_idx + 1];
                b       = (double) in_buff[src_idx + 2];
                l       = (((((double) 0.587 * g) + ((double) 0.114 * b)) / l_corr) + (cross * r_corr * r));

                if (l < (double) 0.0)
                    l = (double) 0.0;
                if (l > (double) 255.0)
                    l = (double) 255.0;

                out_buff[dst_idx] = l;
            }
        }

        // Right.
        for (y = 0; y < size_y; y++)
        {
            for (x = 0; x < size_x; x++)
            {
                src_idx = ((y * size_x) + x) * 3;
                dst_idx = ((y * size_x * 2) + x) + size_x;

                r       = (double) in_buff[src_idx];
                g       = (double) in_buff[src_idx + 1];
                b       = (double) in_buff[src_idx + 2];
                l       = ((cross * (((double) 0.587 * g) + ((double) 0.114 * b)) / l_corr) + (r_corr * r));

                if (l < (double) 0.0)
                    l = (double) 0.0;
                if (l > (double) 255.0)
                    l = (double) 255.0;

                out_buff[dst_idx] = l;
            }
        }
    }

    // Write result.
    {
        int  bytes_written, bytes_to_write;
        unsigned char *s;

        bytes_to_write = nbytes_out;
        s = out_buff;
        while (bytes_to_write > 0)
        {
            bytes_written = write(fileno(stdout), s, bytes_to_write);

            if (bytes_written <= 0)
            {
                fprintf(stderr, "%s: Error writing output data.\n", argv[0]);
                return (errno);
            }

            bytes_to_write -= bytes_written;
            s += bytes_written;
        }
    }

    return (0);
}
