/**
 * Copyright note: Redistribution and use in source, with or without modification, are permitted.
 * 
 * Created: March 2016;
 *
 * @author: Uwe Hahne SICK AG, Waldkirch email: techsupport0905@sick.de Last commit: $Date: 2015-01-21 13:56:28 +0100 (Mi,
 *          21 Jan 2015) $ Last editor: $Author: hahneuw $
 *
 *          Version "$Revision: 8900 $"
 *
 */
package de.sick.svs.api.samples;

import java.util.List;

import de.sick.svs.api.AbstractDataListener;
import de.sick.svs.api.DataReceiverFactory;
import de.sick.svs.api.DeviceConfigurationFactory;
import de.sick.svs.api.DeviceFactory;
import de.sick.svs.api.IData;
import de.sick.svs.api.IDataChannel;
import de.sick.svs.api.IDataReceiver;
import de.sick.svs.api.IDevice;
import de.sick.svs.api.IDeviceConfiguration;
import de.sick.svs.api.ag.ICartesianReduction;
import de.sick.svs.api.ag.IPolar2DReduction;
import de.sick.svs.api.geometry.IVector3f;

/**
 * Demonstrator class for data reduction
 *
 */
public class DataReductionDemonstrator
{
    static IDevice ms_device;

    /**
     * This method demonstrates the data reception. It retrieves data frames for one second and prints out the distance of
     * the center pixel.
     */
    static void runDemo(String ipAddress, String filename)
    {
        // Initialize device
        System.out.print("Init device...");
        ms_device = DeviceFactory.obtainDevice(ipAddress, filename);
        System.out.println("done.");

        System.out.print("Trying to connect...");
        ms_device.connect();

        if (ms_device.isConnected())
        {
            System.out.println("done.");

            // show frame rate reduction
            showFrameRateReduction(ipAddress);

            // show polar 2D reduction
            showPolar2DReduction(ipAddress);

            // show Cartesian reduction
            showCartesianReduction(ipAddress);

            // Disconnect device
            ms_device.disconnect();
        }
        else
        {
            System.out.println("Failed to connect.");
        }
    }

    private static void showFrameRateReduction(String ipAddress)
    {
        // Initialize data receiver
        IDataReceiver dataReceiver = DataReceiverFactory.obtainDataReceiver(ipAddress);
        // Initialize data listener (where the data processing should be done)
        AbstractDataListener dataListener = new AbstractDataListener()
        {

            @Override
            public IData getData()
            {
                // not needed
                return null;
            }

            @Override
            public int getDataCount()
            {
                // not needed
                return 0;
            }

            @Override
            public void handleIncomingData(IData data)
            {
                if (data.getAvailableChannels().contains(IDataChannel.DEPTHMAP))
                {
                    long frameNumber = data.getDepthMapData().getFrameNumber();
                    System.out.println("Data received - Device frame number: " + frameNumber);
                }
            }

            @Override
            public void reset()
            {
                // not needed
            }

        };

        System.out.println("Frame rate not reduced:");
        dataReceiver.addListener(dataListener); // Add data listener to receiver
        dataReceiver.startListening(); // Start data reception

        try
        {
            Thread.sleep(500L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        dataReceiver.stopListening();

        ms_device.login(3, "CLIENT");
        IDeviceConfiguration deviceConfig = DeviceConfigurationFactory.obtainDeviceConfiguration(ms_device);

        int initialValue = deviceConfig.readFrameRateReduction();
        if (initialValue == -1)
        {
            System.out.println("Frame rate reduction is not available.");
            ms_device.logout();
            return;
        }

        int targetValue = 10;
        if (deviceConfig.setFrameRateReduction(targetValue))
        {
            // wait for 3 seconds so that reduction can be demonstrated
            System.out.println("Frame rate reduced by " + targetValue + ":");
            dataReceiver.startListening(); // Start data reception
            try
            {
                Thread.sleep(3000L);
            }
            catch (InterruptedException e)
            {
                e.printStackTrace();
            }
            dataReceiver.stopListening();
            // set back to initial value
            deviceConfig.setFrameRateReduction(initialValue);

        }
        ms_device.logout();
    }

    private static void showPolar2DReduction(String ipAddress)
    {

        // Initialize data receiver
        IDataReceiver dataReceiver = DataReceiverFactory.obtainDataReceiver(ipAddress);
        // Initialize data listener (where the data processing should be done)
        AbstractDataListener dataListener = new AbstractDataListener()
        {

            @Override
            public IData getData()
            {
                // not needed
                return null;
            }

            @Override
            public int getDataCount()
            {
                // not needed
                return 0;
            }

            @Override
            public void handleIncomingData(IData data)
            {
                if (data.getAvailableChannels().contains(IDataChannel.POLAR2D))
                {
                    // Get the data
                    List<Float> floatData = data.getPolar2DData().getFloatData();
                    System.out.println("List of polar 2D scan points:");
                    for (float polarScanPoint : floatData)
                    {
                        System.out.print(String.format("%.2f, ", polarScanPoint));
                    }
                    System.out.println("");
                }
            }

            @Override
            public void reset()
            {
                // not needed
            }

        };

        // Add data listener to receiver
        dataReceiver.addListener(dataListener);

        ms_device.login(3, "CLIENT");

        // enable Cartesian reduction
        IDeviceConfiguration myConfig = DeviceConfigurationFactory.obtainDeviceConfiguration(ms_device);

        ICartesianReduction cartRed = myConfig.getCartesianReduction();

        IPolar2DReduction polarRed = myConfig.getPolar2DReduction();

        // check initial configuration
        boolean cartAlreadyEnabled = cartRed.isEnabled();
        boolean polarAlreadyEnabled = polarRed.isEnabled();
        boolean polarDataChannelAlreadyEnabled = myConfig.isDataChannelEnabled(IDataChannel.POLAR2D);
        if (cartAlreadyEnabled)
        {
            System.out.println("Cartesian reduction needs to be disabled.");
            cartRed.disable();
        }
        if (!polarAlreadyEnabled)
        {
            System.out.println("Polar 2D reduction needs to be enabled.");
            polarRed.enable();
        }

        if (!polarDataChannelAlreadyEnabled)
        {
            myConfig.enableDataChannel(IDataChannel.POLAR2D);
        }

        // Start data reception
        dataReceiver.startListening();

        try
        {
            Thread.sleep(1500L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        dataReceiver.stopListening();

        if (!polarAlreadyEnabled)
        {
            System.out.println("Polar 2D reduction will be disabled again.");
            polarRed.disable();
        }

        if (cartAlreadyEnabled)
        {
            System.out.println("Cartesian reduction will be enabled again.");
            cartRed.enable();
        }

        if (!polarDataChannelAlreadyEnabled)
        {
            myConfig.disableDataChannel(IDataChannel.POLAR2D);
        }
        ms_device.logout();
    }

    private static void showCartesianReduction(String ipAddress)
    {
        // Initialize data receiver
        IDataReceiver dataReceiver = DataReceiverFactory.obtainDataReceiver(ipAddress);
        // Initialize data listener (where the data processing should be done)
        AbstractDataListener dataListener = new AbstractDataListener()
        {

            @Override
            public IData getData()
            {
                // not needed
                return null;
            }

            @Override
            public int getDataCount()
            {
                // not needed
                return 0;
            }

            @Override
            public void handleIncomingData(IData data)
            {
                if (data.getAvailableChannels().contains(IDataChannel.CARTESIAN))
                {
                    // Get the data
                    List<IVector3f> pointCloud = data.getCartesianData().getPointCloud();
                    System.out.println("Cartesian point cloud:");
                    for (IVector3f point : pointCloud)
                    {
                        System.out.print(String.format("[%.2f, %.2f, %.2f], ", point.x(), point.y(), point.z()));
                    }
                    System.out.println("");
                }
            }

            @Override
            public void reset()
            {
                // not needed
            }

        };

        // Add data listener to receiver
        dataReceiver.addListener(dataListener);

        ms_device.login(3, "CLIENT");

        // enable Cartesian reduction
        IDeviceConfiguration myConfig = DeviceConfigurationFactory.obtainDeviceConfiguration(ms_device);

        ICartesianReduction cartRed = myConfig.getCartesianReduction();

        IPolar2DReduction polarRed = myConfig.getPolar2DReduction();

        // check initial configuration
        boolean cartAlreadyEnabled = cartRed.isEnabled();
        boolean polarAlreadyEnabled = polarRed.isEnabled();
        boolean cartesianDataChannelAlreadyEnabled = myConfig.isDataChannelEnabled(IDataChannel.CARTESIAN);
        if (polarAlreadyEnabled)
        {
            System.out.println("Polar reduction needs to be disabled.");
            polarRed.disable();
        }
        if (!cartAlreadyEnabled)
        {
            System.out.println("Cartesian reduction needs to be enabled.");
            cartRed.enable();
        }

        if (!cartesianDataChannelAlreadyEnabled)
        {
            myConfig.enableDataChannel(IDataChannel.CARTESIAN);
        }

        // Start data reception
        dataReceiver.startListening();

        try
        {
            Thread.sleep(1500L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        dataReceiver.stopListening();

        if (!cartAlreadyEnabled)
        {
            System.out.println("Cartesian reduction will be disabled again.");
            cartRed.disable();
        }

        if (polarAlreadyEnabled)
        {
            System.out.println("Polar 2D reduction will be enabled again.");
            polarRed.enable();
        }

        if (!cartesianDataChannelAlreadyEnabled)
        {
            myConfig.disableDataChannel(IDataChannel.CARTESIAN);
        }
        ms_device.logout();

    }

    /**
     * Checks if the connected device supports data reduction
     */
    public static boolean checkSupport(String ipAddress, String filename)
    {
        boolean result = false;
        System.out.print("Init device...");
        ms_device = DeviceFactory.obtainDevice(ipAddress, filename);
        System.out.println("done.");

        System.out.print("Trying to connect...");
        ms_device.connect();

        if (ms_device.isConnected())
        {
            System.out.println("done.");

            String deviceName = ms_device.readDeviceName();

            if (deviceName.contains("AG"))
                result = true;

            // Disconnect device
            ms_device.disconnect();
        }
        else
        {
            System.out.println("Failed to connect.");
        }
        return result;
    }
}
