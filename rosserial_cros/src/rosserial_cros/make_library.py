#!/usr/bin/env python

#####################################################################
# Software License Agreement (BSD License)
#
# Copyright (c) 2011, Willow Garage, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of Willow Garage, Inc. nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

from __future__ import print_function

__author__ = "jpa@git.mail.kapsi.fi Petteri Aimonen"
# rosserial_cros generator is based on rosserial_client 0.8.0 generator
# This generates serializers / deserializers in RAPL-3 language.

import roslib
import roslib.srvs
import roslib.message
import traceback

import os, sys, re

# for copying files
import shutil

#####################################################################
# Data Types

class BaseDataType(object):
    def __init__(self, name, cros_type, bytes):
        self.name = name
        self.type = cros_type
        self.bytes = bytes
    
    def make_defines(self, f):
        pass
    
    def make_declaration(self, f):
        f.write('  %s %s\n' % (self.type, self.name) )

class ConstantType(BaseDataType):
    def __init__(self, package, name, value):
        self.package = package
        self.name = name
        self.value = value

    def make_declaration(self, f):
        f.write('const %s_%s = %s\n' % (self.package, self.name, self.value))

class IntegerDataType(BaseDataType):
    """Up to 32-bit integer values"""

    def __init__(self, name, cros_type, bytes):
        super(IntegerDataType, self).__init__(name, cros_type, bytes)

    def serialize(self, f):
        f.write('  offset = rosmsg_int_serialize(outbuf, offset, msg.%s, %d)\n' % (self.name, self.bytes))

    def deserialize(self, f):
        f.write('  offset = rosmsg_int_deserialize(inbuf, offset, msg.%s, %d)\n' % (self.name, self.bytes))

class Int64DataType(BaseDataType):
    """64-bit integer values"""

    def __init__(self, name, cros_type, bytes):
        super(Int64DataType, self).__init__(name, cros_type, bytes)

    def serialize(self, f):
        f.write('  offset = rosmsg_int_serialize(outbuf, offset, msg.%s[0], 4)\n' % self.name)
        f.write('  offset = rosmsg_int_serialize(outbuf, offset, msg.%s[1], 4)\n' % self.name)

    def deserialize(self, f):
        f.write('  offset = rosmsg_int_deserialize(inbuf, offset, msg.%s[0], 4)\n' % self.name)
        f.write('  offset = rosmsg_int_deserialize(inbuf, offset, msg.%s[1], 4)\n' % self.name)

class MessageDataType(BaseDataType):
    """ For when our data type is another message. """

    def __init__(self, name, cros_type, bytes):
        super(MessageDataType, self).__init__(name, cros_type, bytes)

    def serialize(self, f):
        f.write('  offset = %s_serialize(outbuf, offset, msg.%s);\n' % (self.type, self.name))

    def deserialize(self, f):
        f.write('  offset = %s_deserialize(inbuf, offset, msg.%s);\n' % (self.type, self.name))

class Float32DataType(BaseDataType):
    """32-bit float values"""

    def __init__(self, name, cros_type, bytes):
        super(Float32DataType, self).__init__(name, cros_type, bytes)

    def serialize(self, f):
        f.write('  offset = rosmsg_float32_serialize(outbuf, offset, msg.%s);\n' % self.name)

    def deserialize(self, f):
        f.write('  offset = rosmsg_float32_deserialize(inbuf, offset, msg.%s);\n' % self.name)

class Float64DataType(BaseDataType):
    """ RAPL-3 has no double datatype, convert to float. """

    def __init__(self, name, cros_type, bytes):
        super(Float64DataType, self).__init__(name, cros_type, bytes)

    def serialize(self, f):
        f.write('  offset = rosmsg_float64_serialize(outbuf, offset, msg.%s);\n' % self.name)

    def deserialize(self, f):
        f.write('  offset = rosmsg_float64_deserialize(inbuf, offset, msg.%s);\n' % self.name)


class StringDataType(BaseDataType):
    """String types, constant maximum length"""

    def __init__(self, name, cros_type, bytes):
        super(StringDataType, self).__init__(name, cros_type, bytes)

    def make_defines(self, f):
        f.write('.ifndef ROSMSG_%s_MAXLEN\n' % self.name.upper())
        f.write('.define ROSMSG_%s_MAXLEN ROSMSG_DEFAULT_MAXLEN\n' % self.name.upper())
        f.write('.endif\n')

    def make_declaration(self, f):
        f.write('  string[ROSMSG_%s_MAXLEN] %s;\n' % (self.name.upper(), self.name) )

    def serialize(self, f):
        f.write('  offset = rosmsg_string_serialize(outbuf, offset, msg.%s);\n' % self.name)

    def deserialize(self, f):
        f.write('  offset = rosmsg_string_deserialize(inbuf, offset, msg.%s);\n' % self.name)

class ArrayDataType(BaseDataType):
    def __init__(self, name, ty, bytes, cls, array_size=None):
        self.name = name
        self.type = ty
        self.bytes = bytes
        self.size = array_size
        self.cls = cls
        self.sizefield = IntegerDataType(self.name + "_count", 'int', 4)

    def make_defines(self, f):
        f.write('.ifndef ROSMSG_%s_MAXCOUNT\n' % self.name.upper())
        f.write('.define ROSMSG_%s_MAXCOUNT ROSMSG_DEFAULT_MAXCOUNT\n' % self.name.upper())
        f.write('.endif\n')

    def make_declaration(self, f):
        if self.size is None:
            self.sizefield.make_declaration(f)
            f.write('  %s %s[ROSMSG_%s_MAXCOUNT];\n' % (self.type, self.name, self.name.upper()))
        else:
            f.write('  %s %s[%d];\n' % (self.type, self.name, self.size))

    def serialize(self, f):
        c = self.cls(self.name + "[i]", self.type, self.bytes)
        
        if self.size == None:
            self.sizefield.serialize(f)
            f.write('  for i = 0 to msg.%s_count - 1\n' % self.name)
            c.serialize(f)
            f.write('  end for\n')
        else:
            f.write('  for i = 0 to %d - 1\n' % self.size)
            c.serialize(f)
            f.write('  end for\n')

    def deserialize(self, f):
        c = self.cls(self.name + "[i]", self.type, self.bytes)
        
        if self.size == None:
            self.sizefield.deserialize(f)
            f.write('  for i = 0 to msg.%s_count - 1\n' % self.name)
            c.deserialize(f)
            f.write('  end for\n')
        else:
            f.write('  for i = 0 to %d\n' % (self.size - 1))
            c.deserialize(f)
            f.write('  end for\n')

ROS_TO_EMBEDDED_TYPES = {
    'bool'    :   ('int',               1, IntegerDataType, []),
    'byte'    :   ('int',               1, IntegerDataType, []),
    'int8'    :   ('int',               1, IntegerDataType, []),
    'char'    :   ('int',               1, IntegerDataType, []),
    'uint8'   :   ('int',               1, IntegerDataType, []),
    'int16'   :   ('int',               2, IntegerDataType, []),
    'uint16'  :   ('int',               2, IntegerDataType, []),
    'int32'   :   ('int',               4, IntegerDataType, []),
    'uint32'  :   ('int',               4, IntegerDataType, []),
    'int64'   :   ('int[2]',            8, Int64DataType, []),
    'uint64'  :   ('int[2]',            8, Int64DataType, []),
    'float32' :   ('float',             4, Float32DataType, []),
    'float64' :   ('float',             4, Float64DataType, []),
    'time'    :   ('rosmsg_ros_time',       0, MessageDataType, []),
    'duration':   ('rosmsg_ros_duration',   0, MessageDataType, []),
    'string'  :   ('string',            0, StringDataType, []),
    'Header'  :   ('rosmsg_std_msgs_Header',  0, MessageDataType, ['std_msgs/Header'])
}

#####################################################################
# Messages

class Message:
    """ Parses message definitions into something we can export. """

    def __init__(self, name, package, definition, md5):

        self.name = name            # name of message/class
        self.package = package      # package we reside in
        self.md5 = md5              # checksum
        self.includes = list()      # other files we must include

        self.data = list()          # data types for code generation
        self.constants = list()

        # parse definition
        for line in definition:
            # prep work
            line = line.strip().rstrip()
            value = None
            if line.find("#") > -1:
                line = line[0:line.find("#")]
            if line.find("=") > -1:
                try:
                    value = line[line.find("=")+1:]
                except:
                    value = '"' + line[line.find("=")+1:] + '"';
                line = line[0:line.find("=")]

            # find package/class name
            line = line.replace("\t", " ")
            l = line.split(" ")
            while "" in l:
                l.remove("")
            if len(l) < 2:
                continue
            ty, name = l[0:2]
            if value != None:
                self.constants.append( ConstantType(package, name, value))
                continue

            try:
                type_package, type_name = ty.split("/")
            except:
                type_package = None
                type_name = ty
            type_array = False
            if type_name.find('[') > 0:
                type_array = True
                try:
                    type_array_size = int(type_name[type_name.find('[')+1:type_name.find(']')])
                except:
                    type_array_size = None
                type_name = type_name[0:type_name.find('[')]

            # convert to RAPL-3 type if primitive, expand name otherwise
            try:
                code_type = ROS_TO_EMBEDDED_TYPES[type_name][0]
                size = ROS_TO_EMBEDDED_TYPES[type_name][1]
                cls = ROS_TO_EMBEDDED_TYPES[type_name][2]
                for include in ROS_TO_EMBEDDED_TYPES[type_name][3]:
                    if include not in self.includes:
                        self.includes.append(include)
            except:
                if type_package == None:
                    type_package = self.package
                if type_package+"/"+type_name not in self.includes:
                    self.includes.append(type_package+"/"+type_name)
                cls = MessageDataType
                code_type = "rosmsg_" + type_package + "_" + type_name
                size = 0
            if type_array:
                self.data.append( ArrayDataType(name, code_type, size, cls, type_array_size ) )
            else:
                self.data.append( cls(name, code_type, size) )

    def _write_serializer(self, f):
        f.write('func rosmsg_%s_%s_serialize(var string[] outbuf, int offset, var rosmsg_%s_%s msg)\n' %
                (self.package, self.name, self.package, self.name))
        for d in self.data:
            d.serialize(f)
        f.write('  return offset;\n');
        f.write('end func\n')
        f.write('\n')

    def _write_deserializer(self, f):
        # deserializer
        f.write('func rosmsg_%s_%s_deserialize(var string[] inbuf, int offset, var rosmsg_%s_%s msg)\n' %
                (self.package, self.name, self.package, self.name))
        for d in self.data:
            d.deserialize(f)
        f.write('  return offset;\n');
        f.write('end func\n')
        f.write('\n')

    def _write_std_includes(self, f):
        f.write('.include "rosmsg.r3"\n')

    def _write_msg_includes(self,f):
        for n in self.includes:
            f.write('.include "%s.r3"\n' % n)

    def _write_defines(self, f):
        f.write('\n')
        for d in self.data:
            d.make_defines(f)

    def _write_constants(self, f):
        f.write('\n')
        for c in self.constants:
            c.make_declaration(f)

    def _write_struct(self, f):
        f.write('\n')
        f.write('typedef rosmsg_%s_%s struct\n' % (self.package, self.name))
        for d in self.data:
            d.make_declaration(f)
        f.write('end struct\n')
        f.write('\n')

    def _write_info(self, f):
        f.write('const rosmsg_%s_%s_type = "%s/%s"\n' % (self.package, self.name, self.package, self.name))
        f.write('const rosmsg_%s_%s_md5 = "%s"\n' % (self.package, self.name, self.md5))
        f.write('\n')

    def make_header(self, f):
        f.write('.ifndef ROSMSG_%s_%s_INCLUDED\n' % (self.package.upper(), self.name.upper()))
        f.write('.define ROSMSG_%s_%s_INCLUDED\n' % (self.package.upper(), self.name.upper()))
        f.write('\n')
        self._write_std_includes(f)
        self._write_msg_includes(f)

        self._write_defines(f)
        self._write_constants(f)
        self._write_struct(f)
        self._write_info(f)
        self._write_serializer(f)
        self._write_deserializer(f)

        f.write('\n.endif\n')

class Service:
    def __init__(self, name, package, definition, md5req, md5res):
        """
        @param name -  name of service
        @param package - name of service package
        @param definition - list of lines of  definition
        """

        self.name = name
        self.package = package

        sep_line = len(definition)
        sep = re.compile('---*')
        for i in range(0, len(definition)):
            if (None!= re.match(sep, definition[i]) ):
                sep_line = i
                break
        self.req_def = definition[0:sep_line]
        self.resp_def = definition[sep_line+1:]

        self.req = Message(name+"Request", package, self.req_def, md5req)
        self.resp = Message(name+"Response", package, self.resp_def, md5res)

    def make_header(self, f):
        f.write('.ifndef ROSSERVICE_%s_%s_INCLUDED\n' % (self.package.upper(), self.name.upper()))
        f.write('.define ROSSERVICE_%s_%s_INCLUDED\n' % (self.package.upper(), self.name.upper()))
        f.write('\n')
        self.req._write_std_includes(f)
        
        includes = self.req.includes
        includes.extend(self.resp.includes)
        includes = list(set(includes))
        for inc in includes:
            f.write('.include "%s.r3"\n' % inc)

        f.write(';; Request\n')
        self.req._write_constants(f)
        self.req._write_defines(f)
        self.req._write_struct(f)
        self.req._write_info(f)
        self.req._write_serializer(f)
        self.req._write_deserializer(f)

        f.write('\n;; Response\n')
        self.resp._write_constants(f)
        self.resp._write_defines(f)
        self.resp._write_struct(f)
        self.resp._write_info(f)
        self.resp._write_serializer(f)
        self.resp._write_deserializer(f)
        
        f.write('.endif\n')


#####################################################################
# Make a Library

def MakeLibrary(package, output_path, rospack):
    pkg_dir = rospack.get_path(package)

    # find the messages in this package
    messages = list()
    if os.path.exists(pkg_dir+"/msg"):
        print('Exporting %s\n'%package)
        sys.stdout.write('  Messages:')
        sys.stdout.write('\n    ')
        for f in os.listdir(pkg_dir+"/msg"):
            if f.endswith(".msg"):
                msg_file = pkg_dir + "/msg/" + f
                # add to list of messages
                print('%s,'%f[0:-4], end='')
                definition = open(msg_file).readlines()
                msg_class = roslib.message.get_message_class(package+'/'+f[0:-4])
                if msg_class:
                    md5sum = msg_class._md5sum
                    messages.append( Message(f[0:-4], package, definition, md5sum) )
                else:
                    err_msg = "Unable to build message: %s/%s\n" % (package, f[0:-4])
                    sys.stderr.write(err_msg)

    # find the services in this package
    if (os.path.exists(pkg_dir+"/srv/")):
        if messages == list():
            print('Exporting %s\n'%package)
        else:
            print('\n')
        sys.stdout.write('  Services:')
        sys.stdout.write('\n    ')
        for f in os.listdir(pkg_dir+"/srv"):
            if f.endswith(".srv"):
                srv_file = pkg_dir + "/srv/" + f
                # add to list of messages
                print('%s,'%f[0:-4], end='')
                definition, service = roslib.srvs.load_from_file(srv_file)
                definition = open(srv_file).readlines()
                srv_class = roslib.message.get_service_class(package+'/'+f[0:-4])
                if srv_class:
                    md5req = srv_class._request_class._md5sum
                    md5res = srv_class._response_class._md5sum
                    messages.append( Service(f[0:-4], package, definition, md5req, md5res ) )
                else:
                    err_msg = "Unable to build service: %s/%s\n" % (package, f[0:-4])
                    sys.stderr.write(err_msg)
        print('\n')
    elif messages != list():
        print('\n')

    # generate for each message
    output_path = output_path + "/" + package
    for msg in messages:
        if not os.path.exists(output_path):
            os.makedirs(output_path)
        header = open(output_path + "/" + msg.name + ".r3", "w")
        msg.make_header(header)
        header.close()

def rosserial_generate(rospack, path, mapping):
    # horrible hack -- make this die
    global ROS_TO_EMBEDDED_TYPES
    ROS_TO_EMBEDDED_TYPES = mapping

    # gimme messages
    failed = []
    for p in sorted(rospack.list()):
        try:
            MakeLibrary(p, path, rospack)
        except Exception as e:
            failed.append(p + " ("+str(e)+")")
            print('[%s]: Unable to build messages: %s\n' % (p, str(e)))
            print(traceback.format_exc())
    print('\n')
    if len(failed) > 0:
        print('*** Warning, failed to generate libraries for the following packages: ***')
        for f in failed:
            print('    %s'%f)
        raise Exception("Failed to generate libraries for: " + str(failed))
    print('\n')

def rosserial_cros_copy_files(rospack, path):
    pass
#    os.makedirs(path+"/ros")
#    os.makedirs(path+"/tf")
#    files = ['duration.cpp',
#             'time.cpp',
#             'ros/duration.h',
#             'ros/msg.h',
#             'ros/node_handle.h',
#             'ros/publisher.h',
#             'ros/service_client.h',
#             'ros/service_server.h',
#             'ros/subscriber.h',
#             'ros/time.h',
#             'tf/tf.h',
#             'tf/transform_broadcaster.h']
#    mydir = rospack.get_path("rosserial_client")
#    for f in files:
#        shutil.copy(mydir+"/src/ros_lib/"+f, path+f)

