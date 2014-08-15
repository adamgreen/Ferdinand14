/*  Copyright (C) 2014  Adam Green (https://github.com/adamgreen)

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
*/
import processing.serial.*;

public class FilteredCompass extends PApplet
{
  public FilteredCompass()
  {
    ConfigFile configFile = new ConfigFile(System.getenv("USER") + ".config");

    m_calibration = new HeadingSensorCalibration();
    m_calibration.accelMin = configFile.getIntVector("compass.accelerometer.min");
    m_calibration.magMin = configFile.getIntVector("compass.magnetometer.min");
    m_calibration.accelMax = configFile.getIntVector("compass.accelerometer.max");
    m_calibration.magMax = configFile.getIntVector("compass.magnetometer.max");
    m_calibration.gyroCoefficientA = configFile.getFloatVector("compass.gyro.coefficient.A");
    m_calibration.gyroCoefficientB = configFile.getFloatVector("compass.gyro.coefficient.B");
    m_calibration.gyroScale = configFile.getFloatVector("compass.gyro.scale");
    
    m_port = new Serial(this, configFile.getString("compass.port"), 230400);
    m_headingSensor = new HeadingSensor(m_port, m_calibration);
  }

  public float getHeading()
  {
    // Calculate the yaw angle (rotation about y axis) from the rotation quaternion.
    PMatrix3D rotationMatrix = quaternionToMatrix(m_rotationQuaternion);
    PVector north = new PVector(rotationMatrix.m00, rotationMatrix.m01, rotationMatrix.m02);
    float headingAngle = atan2(-north.z, north.x);
    return headingAngle;
  }

  public void serialEvent(Serial port)
  {
    m_headingSensor.update();
    updateHeading();
  }

  protected void updateHeading()
  {
    if (!m_isInitialized)
    {
      m_rotationQuaternion = calculateAccelMagRotation(m_headingSensor.getCurrent());
      m_isInitialized = true;
    }
    
    // Calculate rotation using Kalman filter.
    m_rotationQuaternion = calculateKalmanRotation(m_headingSensor.getCurrent(), m_rotationQuaternion);
  }
  
  protected float[] calculateKalmanRotation(FloatHeading heading, float[] currentQuaternion)
  {
    // System model covariance matrices which don't change.
    final float gyroVariance = 6.5E-11;
    final float accelMagVariance = 1.0E-5;
    final PMatrix3D Q = new PMatrix3D(gyroVariance,         0.0f,         0.0f,         0.0f,
                                              0.0f, gyroVariance,         0.0f,         0.0f,
                                              0.0f,         0.0f, gyroVariance,         0.0f,
                                              0.0f,         0.0f,         0.0f, gyroVariance);
    final PMatrix3D R = new PMatrix3D(accelMagVariance,             0.0f,             0.0f,             0.0f,
                                                  0.0f, accelMagVariance,             0.0f,             0.0f,
                                                  0.0f,             0.0f, accelMagVariance,             0.0f,
                                                  0.0f,             0.0f,             0.0f, accelMagVariance);
                                            
    // Swizzle the axis so that gyro's axis match overall sensor setup.
    float gyroX = heading.m_gyroY;
    float gyroY = heading.m_gyroZ;
    float gyroZ = heading.m_gyroX;
  
    // Construct matrix which applies gyro rates (derivatives) to quaternion.
    // This will be the A matrix for the system model.
    final float timeScale = (1.0f / 100.0f);
    final float scaleFactor = timeScale * 0.5f;
    gyroX *= scaleFactor;
    gyroY *= scaleFactor;
    gyroZ *= scaleFactor;
    PMatrix3D A = new PMatrix3D( 1.0f, -gyroX, -gyroY, -gyroZ,
                                 gyroX,   1.0f,  gyroZ, -gyroY,
                                 gyroY, -gyroZ,   1.0f,  gyroX,
                                 gyroZ,  gyroY, -gyroX, 1.0f);
    
    // Calculate Kalman prediction for x and error.
    float[] xPredicted = new float[4];
    A.mult(currentQuaternion, xPredicted);
    quaternionNormalize(xPredicted);
    
    PMatrix3D PPredicted = A.get();
    PMatrix3D ATranspose = A.get();
    ATranspose.transpose();
    PPredicted.apply(m_kalmanP);
    PPredicted.apply(ATranspose);
    matrixAdd(PPredicted, Q);
    
    // Calculate the Kalman gain.
    // Simplified a bit since the H matrix is the identity matrix.
    PMatrix3D K = PPredicted.get();
    PMatrix3D temp = PPredicted.get();
    matrixAdd(temp, R);
    temp.invert();
    K.apply(temp);
  
    // Fetch the accelerometer/magnetometer measurements as a quaternion.
    float[] z = calculateAccelMagRotation(heading);
    
    // Flip the quaternion (q == -q for quaternions) if the angle is obtuse.
    if (quaternionDot(z, xPredicted) < 0.0f)
    {
      quaternionFlip(z);
    }
    
    // Calculate the Kalman estimates.
    // Again, simplified a bit since H is the identity matrix.
    temp = K.get();
    float[] correction = new float[4];
    quaternionSubtract(z, xPredicted);
    temp.mult(z, correction);
    quaternionAdd(xPredicted, correction);
    float[] x = xPredicted;
    
    temp = K.get();
    temp.apply(PPredicted);
    matrixSubtract(PPredicted, temp);
    m_kalmanP = PPredicted;

    return x;
  }

  protected void matrixAdd(PMatrix3D m1, PMatrix3D m2)
  {
    m1.m00 += m2.m00;
    m1.m01 += m2.m01;
    m1.m02 += m2.m02;
    m1.m03 += m2.m03;
    m1.m10 += m2.m10;
    m1.m11 += m2.m11;
    m1.m12 += m2.m12;
    m1.m13 += m2.m23;
    m1.m20 += m2.m20;
    m1.m21 += m2.m21;
    m1.m22 += m2.m22;
    m1.m23 += m2.m23;
    m1.m30 += m2.m30;
    m1.m31 += m2.m31;
    m1.m32 += m2.m32;
    m1.m33 += m2.m33;
  }

  protected void matrixSubtract(PMatrix3D m1, PMatrix3D m2)
  {
    m1.m00 -= m2.m00;
    m1.m01 -= m2.m01;
    m1.m02 -= m2.m02;
    m1.m03 -= m2.m03;
    m1.m10 -= m2.m10;
    m1.m11 -= m2.m11;
    m1.m12 -= m2.m12;
    m1.m13 -= m2.m23;
    m1.m20 -= m2.m20;
    m1.m21 -= m2.m21;
    m1.m22 -= m2.m22;
    m1.m23 -= m2.m23;
    m1.m30 -= m2.m30;
    m1.m31 -= m2.m31;
    m1.m32 -= m2.m32;
    m1.m33 -= m2.m33;
  }

  protected float[] calculateAccelMagRotation(FloatHeading heading)
  {
    // Setup gravity (down) and north vectors.
    // NOTE: The fields are swizzled to make the axis on the device match the axis on the screen.
    PVector down = new PVector(heading.m_accelY, heading.m_accelZ, heading.m_accelX);
    PVector north = new PVector(-heading.m_magX, heading.m_magZ, heading.m_magY);
  
    // Project the north vector onto the earth surface plane.
    down.normalize();
    north.sub(PVector.mult(down, north.dot(down)));
    north.normalize();
  
    // To create a rotation matrix, we need all 3 basis vectors so calculate the vector which
    // is orthogonal to both the down and north vectors (ie. the normalized cross product).
    PVector west = north.cross(down);
    west.normalize();
    PMatrix3D rotationMatrix = new PMatrix3D(north.x, north.y, north.z, 0.0,
                                             down.x, down.y, down.z, 0.0,
                                             west.x, west.y, west.z, 0.0,
                                             0.0, 0.0, 0.0, 1.0);
    float[] rotationQuaternion = matrixToQuaternion(rotationMatrix);
    
    return rotationQuaternion;
  }
  
  protected HeadingSensorCalibration m_calibration;
  protected Serial                   m_port;
  protected HeadingSensor            m_headingSensor;
  protected boolean                  m_isInitialized = false;
  protected float[]                  m_rotationQuaternion = {1.0f, 0.0f, 0.0f, 0.0f};
  protected final float              m_initVariance = 1.0E-4;
  protected PMatrix3D                m_kalmanP = new PMatrix3D(m_initVariance,           0.0f,           0.0f,           0.0f,
                                                                         0.0f, m_initVariance,           0.0f,           0.0f,
                                                                         0.0f,           0.0f, m_initVariance,           0.0f, 
                                                                         0.0f,           0.0f,           0.0f, m_initVariance);
}

