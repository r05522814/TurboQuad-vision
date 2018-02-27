/**
 * Copyright note: Redistribution and use in source, with or without modification, are permitted.
 * 
 * Created: March 2016;
 *
 * @author: Uwe Hahne SICK AG, Waldkirch email: techsupport0905@sick.de Last commit: $Date: 2015-01-21 13:56:28 +0100 (Mi,
 *          21 Jan 2015) $ Last editor: $Author: hahneuw $
 *
 *          Version "$Revision: 9661 $"
 *
 */
package de.sick.svs.api.samples;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import de.sick.svs.api.AbstractDataListener;
import de.sick.svs.api.DataReceiverFactory;
import de.sick.svs.api.DeviceFactory;
import de.sick.svs.api.IData;
import de.sick.svs.api.IDataChannel;
import de.sick.svs.api.IDataReceiver;
import de.sick.svs.api.IDevice;
import de.sick.svs.api.ag.ICartesianData;
import de.sick.svs.api.ag.IDepthMapData;
import de.sick.svs.api.ag.IPolar2DData;
import de.sick.svs.api.geometry.IMatrix4f;
import de.sick.svs.api.geometry.IVector3f;
import de.sick.svs.api.internal.geometry.Vector3f;

/**
 * Demonstrator class for data reception
 * 
 */
public class DataReceptionDemonstrator
{
    /**
     * This method demonstrates the data reception. It retrieves data frames for one second and prints out the distance of
     * the center pixel.
     */
    public static void receiveData(String ipAddress)
    {
        // Initialize data receiver
        IDataReceiver dataReceiver = DataReceiverFactory.obtainDataReceiver(ipAddress);
        // Initialize data listener (where the data processing should be done)
        AbstractDataListener myDataListener = new AbstractDataListener()
        {

            /**
             * This method is called by the data receiver after a new frame has been received and data has been extracted.
             * Here, you should do whatever you want with the data. In this example the distance value of the center pixel
             * is printed to the console.
             */
            @Override
            public void handleIncomingData(IData data)
            {
                System.out.println("New incoming data:\n");
                if (data.getAvailableChannels().contains(IDataChannel.DEPTHMAP))
                {
                    System.out.println("Data contains a depthmap:");
                    IDepthMapData dmData = data.getCopy().getDepthMapData();
                    // Extract distance map from the incoming data blob.
                    int[][] distanceMap = DataReceptionHelper.getDistanceMapFromData(dmData);
                    // and in the same way for confidence and intensity
                    int[][] intensityMap = DataReceptionHelper.getIntensityMapFromData(dmData);
                    int[][] confidenceMap = DataReceptionHelper.getConfidenceMapFromData(dmData);

                    // Print the distance value of the center pixel
                    int numCols = dmData.getCameraParameters().getNumberOfColumns();
                    int numRows = dmData.getCameraParameters().getNumberOfRows();

                    int midHorizontal = numCols / 2;
                    int midVertical = numRows / 2;
                    System.out.println("Center pixel is at a distance of " + distanceMap[midHorizontal][midVertical] +
                        " mm.");
                    System.out.println("and has a intensity of " + intensityMap[midHorizontal][midVertical]);
                    System.out.println("and a confidence of " + confidenceMap[midHorizontal][midVertical]);

                    System.out.println("Timestamp: " + dmData.getTimestamp());
                    System.out.println("Data quality is " + dmData.getDataQuality());
                    System.out.println("Device status is " + dmData.getStatus());
                    System.out.println(" --> End of depth map data.\n");
                }
                if (data.getAvailableChannels().contains(IDataChannel.POLAR2D))
                {
                    System.out.println("Data contains polar scan data:");
                    IPolar2DData polarData = data.getPolar2DData();
                    float angleFirstScanPoint = polarData.getAngleOfFirstDataPoint();
                    float angularResolution = polarData.getAngularResolution();
                    int numScans = polarData.getFloatData().size();
                    System.out.println("Angle of first scan point = " + angleFirstScanPoint);
                    System.out.println("Angular resolution = " + angularResolution);
                    System.out.println("Number of scan points = " + numScans);
                    System.out.println("Incoming scan data:");
                    Iterator<Float> floatListIterator = polarData.getFloatData().iterator();
                    while (floatListIterator.hasNext())
                    {
                        System.out.print(floatListIterator.next() + ", ");
                    }
                    System.out.println(" --> data complete.");

                    // Comparison to Sopas parameters
                    float startAngle = angleFirstScanPoint - (angularResolution / 2);
                    float endAngle = angleFirstScanPoint + (angularResolution * (numScans - 0.5f));
                    System.out.println("Start angle (Sopas) = " + startAngle);
                    System.out.println("End angle (Sopas) = " + endAngle);
                    System.out.println("Number of sectors (Sopas) = " + numScans);
                    System.out.println(" --> End of polar scan data.\n");
                }
                if (data.getAvailableChannels().contains(IDataChannel.CARTESIAN))
                {
                    System.out.println("Data contains Cartesian data:");
                    ICartesianData cartData = data.getCartesianData();
                    List<IVector3f> pointCloud = cartData.getPointCloud();
                    List<Float> confidenceValues = cartData.getConfidenceValues();
                    // assert that pointCloud and confidence valus have same amount
                    if (pointCloud.size() == confidenceValues.size())
                    {
                        System.out.println("Cartesian point cloud (with confidence values):");
                        for (int i = 0; i < pointCloud.size(); i++)
                        {
                            System.out.print(String.format("[%.2f, %.2f, %.2f] (%.2f), ",
                                pointCloud.get(i).x(),
                                pointCloud.get(i).y(),
                                pointCloud.get(i).z(),
                                confidenceValues.get(i)));
                        }

                        System.out.println("");
                    }
                    else
                    {
                        System.out.println("ERROR: pointCloud.size() != confidenceValues.size()");
                    }
                }
            }

            @Override
            public IData getData()
            {
                // Not needed in this example
                return null;
            }

            @Override
            public int getDataCount()
            {
                // Not needed in this example
                return 0;
            }

            @Override
            public void reset()
            {
                // Not needed in this example
            }
        };
        // Add data listener to receiver
        dataReceiver.addListener(myDataListener);
        // Start data reception
        dataReceiver.startListening();
        // check if connection is established
        if (!dataReceiver.isListening())
        {
            System.out.println("Failed to connect.");
            return;
        }

        // wait for incoming data
        try
        {
            Thread.sleep(2000L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }

        // Stop data reception
        dataReceiver.stopListening();
    }

    /**
     * Demonstrates how to obtain data with connecting to the control channel of the device in order to change device
     * settings.
     */
    public static void receiveDataWithDeviceControl(String ipAddress, String filename)
    {
        // Initialize device
        System.out.print("Init device...");
        IDevice device = DeviceFactory.obtainDevice(ipAddress, filename);
        System.out.println("done.");

        System.out.print("Trying to connect...");
        device.connect();

        if (device.isConnected())
        {
            System.out.println("done.");
            boolean imageAcquisitonWasStarted = false;
            if (device.isImageAcquisitionStarted())
            {
                imageAcquisitonWasStarted = true;
                System.out.println("Stopping image acquisition.");
                device.stopImageAcquisition();
                try
                {
                    // wait until image acquisition is stopped.
                    Thread.sleep(1000L);
                }
                catch (InterruptedException e)
                {
                    e.printStackTrace();
                }
            }

            // Initialize data receiver
            IDataReceiver dataReceiver = DataReceiverFactory.obtainDataReceiver(ipAddress);

            // Initialize data listener (where the data processing should be
            // done)
            AbstractDataListener myDataListener = new AbstractDataListener()
            {
                private int m_dataCount = 0;
                private IData m_data = null;

                /**
                 * This method is called by the data receiver after a new frame has been received and data has been
                 * extracted. The processing of the data should be done in this method.
                 */
                @Override
                public void handleIncomingData(IData incomingData)
                {
                    m_dataCount++;
                    m_data = incomingData;
                }

                @Override
                public IData getData()
                {
                    // Return last obtained data
                    return m_data;
                }

                @Override
                public int getDataCount()
                {
                    // Simply return data count
                    return m_dataCount;
                }

                @Override
                public void reset()
                {
                    // Reset data but not the counter
                    m_data = null;
                    m_dataCount = 0;
                }
            };
            // Add data listener to receiver
            dataReceiver.addListener(myDataListener);

            IData myData = null;

            // Acquiring frames via single step
            dataReceiver.startListening(); // Start data reception

            System.out.println("Single step acquisition");
            device.triggerSingleImageAcquisition();

            boolean dataReceived = false;
            while (!dataReceived)
            {
                System.out.println("Checking if data is available.");
                try
                {
                    // waiting for the data to be transferred to the host.
                    Thread.sleep(50L);
                    // Note that usually 50 milliseconds is a good waiting time, but if some other system task (e.g.
                    // garbage collector) is interfering with the data receiver, it might take up to 1.5 seconds until the
                    // next frame is received.
                }
                catch (InterruptedException e)
                {
                    e.printStackTrace();
                }
                myData = myDataListener.getData();
                if (myData != null)
                {
                    dataReceived = true;
                }

            }

            myDataListener.reset(); // Reset frame counter
            dataReceiver.stopListening(); // Stop data reception

            if (myData.getAvailableChannels().contains(IDataChannel.DEPTHMAP))
            {
                IDepthMapData dmData = myData.getDepthMapData();
                int[][] distanceMap = DataReceptionHelper.getDistanceMapFromData(dmData);
                int[][] intensityMap = DataReceptionHelper.getIntensityMapFromData(dmData);
                int[][] confidenceMap = DataReceptionHelper.getConfidenceMapFromData(dmData);

                // save maps as .PNG file
                Date now = new Date();
                SimpleDateFormat sdf = new SimpleDateFormat("hhmmsss");
                DataReceptionHelper.saveMapToImage(distanceMap, String.format("distance_%s.png", sdf.format(now)), 0,
                    7500);
                DataReceptionHelper.saveMapToImage(intensityMap, String.format("intensity_%s.png", sdf.format(now)), 0,
                    2 * Short.MAX_VALUE);
                DataReceptionHelper.saveMapToImage(confidenceMap, String.format("confidence_%s.png", sdf.format(now)),
                    0,
                    2 * Short.MAX_VALUE);

                double[][] pointCloudCam = DataReceptionHelper.getPointCloudFromDataInCameraSpace(dmData);

                // Print the x,y and z values of the central data point
                int numCols = dmData.getCameraParameters().getNumberOfColumns();

                // compute the index of the point corresponding to the center pixel
                float cX = dmData.getCameraParameters().getCenter().x();
                float cY = dmData.getCameraParameters().getCenter().y();
                int midIndex = (int) ((cY - 1) * numCols + cX);

                System.out.println("Center data point is at XYZ = (" + pointCloudCam[0][midIndex] + ", " +
                    pointCloudCam[1][midIndex] + ", " + pointCloudCam[2][midIndex] + ")");

                // Transform the point cloud from camera coordinates into world
                // coordinates.

                double[][] pointCloudWorld = new double[3][pointCloudCam[0].length];

                // get camera to world transformation matrix
                IMatrix4f cameraToWorldMatrix = dmData.getCameraParameters().getCameraToWorldMatrix();

                for (int i = 0; i < pointCloudCam[0].length; i++)
                {
                    // point coordinates in camera space
                    float xCam = (float) pointCloudCam[0][i];
                    float yCam = (float) pointCloudCam[1][i];
                    float zCam = (float) pointCloudCam[2][i];

                    // transform point into world space
                    IVector3f xyzWorld = cameraToWorldMatrix.transform(Vector3f.xyz(xCam, yCam, zCam));
                    pointCloudWorld[0][i] = xyzWorld.x();
                    pointCloudWorld[1][i] = xyzWorld.y();
                    pointCloudWorld[2][i] = xyzWorld.z();
                }

                // save point clouds as PCD file
                DataReceptionHelper.savePointCloudAsPCDFile(pointCloudCam, "cloud_camera.pcd");
                DataReceptionHelper.savePointCloudAsPCDFile(pointCloudWorld, "cloud_world.pcd");
            }

            // restart image acquisition if it was started in order to not
            // change the device state
            if (imageAcquisitonWasStarted)
            {
                device.startImageAcquisition();
            }
            // Disconnect device
            device.disconnect();
        }
        else
        {
            System.out.println("Failed to connect.");
        }
    }

    /**
     * Checks if the connection can be established.
     */
    public static boolean checkConnection(String ipAddress, String filename)
    {
        boolean result = false;
        System.out.print("Init device...");
        IDevice device = DeviceFactory.obtainDevice(ipAddress, filename);
        System.out.println("done.");

        System.out.print("Trying to connect...");
        device.connect();

        if (device.isConnected())
        {
            System.out.println("done.");

            result = true;

            // Disconnect device
            device.disconnect();
        }
        else
        {
            System.out.println("Failed to connect.");
        }
        return result;
    }
}
