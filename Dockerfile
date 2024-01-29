FROM ros:noetic-ros-base

# USE BASH
SHELL ["/bin/bash", "-c"]

# RUN LINE BELOW TO REMOVE debconf ERRORS (MUST RUN BEFORE ANY apt-get CALLS)
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends apt-utils python3-pip git

RUN apt install python3-catkin-tools -y

RUN mkdir -p /catkin_ws/src

RUN cd /catkin_ws/src/ && git clone -b noetic-devel https://github.com/safijari/ar_track_alvar && cd ar_track_alvar && git submodule update --init --recursive
ADD rosdep.yaml /rosdep.yaml
RUN echo "yaml file:///rosdep.yaml" > /etc/ros/rosdep/sources.list.d/99-custom.list
RUN rosdep update
RUN rosdep install -y -r --from-paths /catkin_ws/src/ar_track_alvar/ --ignore-src --rosdistro=noetic

RUN source /opt/ros/noetic/setup.bash \ 
    && cd /catkin_ws/src \
    && catkin_init_workspace \
    && cd .. \
    && catkin config --install \
    && catkin build -DCMAKE_BUILD_TYPE=Release

RUN apt install python3-bloom fakeroot debhelper magics++ libboost-thread-dev -y

RUN cd /catkin_ws/src/ar_track_alvar/ar_track_alvar_msgs/ && bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic
RUN cd /catkin_ws/src/ar_track_alvar/ar_track_alvar_msgs/ && fakeroot debian/rules binary

RUN apt install /catkin_ws/src/ar_track_alvar/*.deb -y

RUN ls /catkin_ws/src/ar_track_alvar

RUN cd /catkin_ws/src/ar_track_alvar/ar_track_alvar/ && bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic
RUN cd /catkin_ws/src/ar_track_alvar/ar_track_alvar/ && fakeroot debian/rules binary

RUN cp /catkin_ws/src/ar_track_alvar/*.deb /catkin_ws
