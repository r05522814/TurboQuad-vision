/**
 * Copyright note: Redistribution and use in source, with or without modification, are permitted.
 * 
 * Created: October 2014;
 *
 * @author: Uwe Hahne, Jens Silva SICK AG, Waldkirch email: techsupport0905@sick.de Last commit: $Date: 2015-01-21
 *          13:56:28 +0100 (Mi, 21 Jan 2015) $ Last editor: $Author: hahneuw $
 *
 *          Version "$Revision: 9661 $"
 *
 */
package de.sick.svs.api.samples;

import java.io.IOException;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.jar.Manifest;
import java.util.logging.Level;

import de.sick.svs.api.DeviceFactory;
import de.sick.svs.api.LoggerConfiguration;

/**
 * This class should illustrate how to receive data from devices of the V3S family.
 */
public class MyV3SDataExample
{

    // Set the device IP address here (use Sopas ET, if you do not know it)
    private static final String IP_ADDRESS = "192.168.1.10";

    public static final String FILENAME_XML = "resources\\V3SCameraEt.cid.processed.xml";

    public static final String LOGGING_CONFIG_FILE = "\\resources\\logging.properties";

    /**
     * The main method explains the necessary steps to initialize, start and stop the data receiver.
     *
     * @param args not in use
     */
    public static void main(String[] args)
    {
        String loggingConfigFile = System.getProperty("user.dir").concat(LOGGING_CONFIG_FILE);
        LoggerConfiguration.activateLogging(loggingConfigFile);
        LoggerConfiguration.testLog(Level.INFO, "message");

        // Reading the version information from the jar file.
        readVersionInformation();

        if (DataReceptionDemonstrator.checkConnection(IP_ADDRESS, FILENAME_XML))
        {

            // Obtain data without controlling the device
            DataReceptionDemonstrator.receiveData(IP_ADDRESS);

            // How to connect to device and control it
            DataReceptionDemonstrator.receiveDataWithDeviceControl(IP_ADDRESS, FILENAME_XML);

            // How to read and write device configuration parameters
            DeviceConfigurationDemonstrator.runDemo(IP_ADDRESS, FILENAME_XML);

            // How to read device diagnostics
            DeviceDiagnosticsDemonstrator.runDemo(IP_ADDRESS, FILENAME_XML);

            if (DataReductionDemonstrator.checkSupport(IP_ADDRESS, FILENAME_XML))
            {
                // How to use data reduction
                DataReductionDemonstrator.runDemo(IP_ADDRESS, FILENAME_XML);
            }
            else
            {
                System.out.println("This device does not support data reduction.");
            }
        }
        else
        {
            System.out.println("The device is not properly connected. Typical reasons are:");
            System.out.println("- cable not connected");
            System.out.println("- device is off");
            System.out.println("- wrong ip address is set. You tried to connect to " + IP_ADDRESS +
                ". Please use Sopas ET to scan for connected devices.");
        }
    }

    /**
     * Reads out the API version and prints it to the console.
     */
    private static void readVersionInformation()
    {
        URLClassLoader cl = (URLClassLoader) (DeviceFactory.class.getClassLoader());
        try
        {
            URL url = cl.findResource("META-INF/MANIFEST.MF");
            Manifest manifest = new Manifest(url.openStream());
            System.out.print("This is " + manifest.getAttributes("de/sick/svs/api/").getValue("Specification-Title"));
            System.out.println(" v" + manifest.getAttributes("de/sick/svs/api/").getValue("Specification-Version"));

        }
        catch (IOException E)
        {
            // handle
            System.out.println("ERROR: Could not find manifest.");
        }
    }
}
