#!/usr/bin/env python

import numpy as np
import os
import sys
import argparse
import glob
import time

import caffe

from caffe.proto import caffe_pb2

import scipy.io

blob = caffe_pb2.BlobProto()
# blob = caffe.proto.caffe_pb2.BlobProto()

f = open('/media/giulia/DATA/DATASETS/iCubWorld30/iCubWorld30_train_mean.binaryproto', "rb")
blob.ParseFromString(f.read())

#f = open('/media/giulia/DATA/DATASETS/iCubWorld30/iCubWorld30_train_mean.binaryproto', 'rb' ).read()
#blob.ParseFromString(f)

f.close()

array1 = caffe.io.blobproto_to_array(blob)
array2 = np.array(array1)
out = array2[0]
np.save( '/media/giulia/DATA/DATASETS/iCubWorld30/iCubWorld30_train_mean.npy' , out )
scipy.io.savemat('iCubWorld30_train_mean.mat', dict(out=out))

#arr = np.array([[1, 2], [3, 4], [5, 6]])
#scipy.io.savemat('prova.mat', dict(arr=arr))
