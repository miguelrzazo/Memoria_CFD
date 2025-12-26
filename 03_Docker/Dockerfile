# OpenFOAM CFD Environment
# Based on microfluidica/openfoam:13 (ARM64 for Mac M1)
FROM microfluidica/openfoam:13

# Set working directory
WORKDIR /home/openfoam/work

# Create user with proper permissions for OpenFOAM
# This ensures #calc works in blockMeshDict
USER openfoam

# Default command
CMD ["/bin/bash"]