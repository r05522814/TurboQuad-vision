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

import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ShortBuffer;
import java.util.Locale;

import javax.imageio.ImageIO;

import de.sick.svs.api.ag.IDepthMapData;
import de.sick.svs.api.geometry.IMatrix4f;
import de.sick.svs.api.geometry.IVector3f;
import de.sick.svs.api.internal.geometry.Vector3f;

/**
 * Helper class for data reception
 *
 */
public class DataReceptionHelper
{
    /**
     * Extract the distance map from the received blob data
     *
     * @param data the received data blob
     * @return the distance map as a two-dimensional array
     */
    static int[][] getDistanceMapFromData(IDepthMapData data)
    {
        int numCols = data.getCameraParameters().getNumberOfColumns(); // null pointer access here
        int numRows = data.getCameraParameters().getNumberOfRows();

        final ByteBuffer distanceByteData = data.getDistanceData();
        int bytesPerPixel = data.getDistanceDataSizeInBytes();
        return getMapFromBuffer(distanceByteData, numCols, numRows, bytesPerPixel);
    }

    /**
     * Extract the intensity map from the received blob data
     *
     * @param data the received data blob
     * @return the intensity map as a two-dimensional array
     */
    static int[][] getIntensityMapFromData(IDepthMapData data)
    {
        int numCols = data.getCameraParameters().getNumberOfColumns();
        int numRows = data.getCameraParameters().getNumberOfRows();

        final ByteBuffer intensityByteData = data.getIntensityData();
        int bytesPerPixel = data.getIntensityDataSizeInBytes();
        return getMapFromBuffer(intensityByteData, numCols, numRows, bytesPerPixel);
    }

    /**
     * Extract the confidence map from the received blob data
     *
     * @param data the received data blob
     * @return the confidence map as a two-dimensional array
     */
    static int[][] getConfidenceMapFromData(IDepthMapData data)
    {
        int numCols = data.getCameraParameters().getNumberOfColumns();
        int numRows = data.getCameraParameters().getNumberOfRows();

        final ByteBuffer confidenceByteData = data.getConfidenceData();
        int bytesPerPixel = data.getConfidenceDataSizeInBytes();
        return getMapFromBuffer(confidenceByteData, numCols, numRows, bytesPerPixel);
    }

    /**
     * Convert the raw data byte buffer (16bit per value) into a two-dimensional map
     *
     * @param buffer The data buffer
     * @param numCols The number of columns (image width)
     * @param numRows The number of rows (image height)
     * @param bytesPerPixel Number of bytes per value - must be 2!
     * @return The data as a two-dimensional array at the given size.
     */
    private static int[][] getMapFromBuffer(ByteBuffer buffer, int numCols, int numRows, int bytesPerPixel)
    {
        buffer.order(java.nio.ByteOrder.LITTLE_ENDIAN);
        // we assume that bytes per pixel equals 2
        if (bytesPerPixel != 2)
        {
            System.out.println("SEVERE: Data format is not the expected! Returning null");
            return null;
        }
        final ShortBuffer data = buffer.asShortBuffer();
        int map[][] = new int[numCols][numRows];

        int srcIdx = 0;

        for (int row = 0; row < numRows; row++)
        {
            for (int col = 0; col < numCols; col++)
            {
                // Java does not support unsigned data types, but the short values are meant as unsigned and have to be
                // casted like this
                map[col][row] = data.get(srcIdx) & 0xFFFF;
                ++srcIdx;
            }
        }
        return map;
    }

    /**
     * Compute a 3D point cloud from the received blob data
     *
     * @param data the received data blob
     * @return the point cloud as a two-dimensional array of size 3xn where n is the number of points
     */
    static double[][] getPointCloudFromDataInCameraSpace(IDepthMapData data)
    {
        int numCols = data.getCameraParameters().getNumberOfColumns();
        int numRows = data.getCameraParameters().getNumberOfRows();
        int distanceMap[][] = getDistanceMapFromData(data);
        double[][] pointCloud = new double[3][numCols * numRows];

        final float cx = data.getCameraParameters().getCenter().x();
        final float cy = data.getCameraParameters().getCenter().y();
        final float fx = data.getCameraParameters().getFocalLength().x();
        final float fy = data.getCameraParameters().getFocalLength().y();

        final float k1 = data.getCameraParameters().getCorrection().getK1();
        final float k2 = data.getCameraParameters().getCorrection().getK2();
        final float f2rc = data.getCameraParameters().getFocalToRayCross();

        // transform each pixel into Cartesian coordinates
        int pIndex = 0;
        for (int row = 0; row < numRows; row++)
        {
            for (int col = 0; col < numCols; col++)
            {
                final int depth = distanceMap[col][row];

                // we map from image coordinates with origin top left and x
                // horizontal (right) and y vertical
                // (downwards) to camera coordinates with origin in center and x
                // to the left and y upwards (seen
                // from the sensor position)
                final double xp = (cx - col) / fx;
                final double yp = (cy - row) / fy;

                // correct the camera distortion
                final double r2 = xp * xp + yp * yp;
                final double r4 = r2 * r2;
                final double k = 1 + k1 * r2 + k2 * r4;
                final double xd = xp * k;
                final double yd = yp * k;

                final double s0 = Math.sqrt(xd * xd + yd * yd + 1.0);
                final double x = xd * depth / s0;
                final double y = yd * depth / s0;
                final double z = depth / s0 - f2rc;
                pointCloud[0][pIndex] = x;
                pointCloud[1][pIndex] = y;
                pointCloud[2][pIndex] = z;
                pIndex++;
            }
        }
        return pointCloud;
    }

    public static double[][] getPointCloudFromDataInWorldSpace(IDepthMapData data)
    {
        int numCols = data.getCameraParameters().getNumberOfColumns();
        int numRows = data.getCameraParameters().getNumberOfRows();
        int distanceMap[][] = getDistanceMapFromData(data);
        double[][] pointCloud = new double[3][numCols * numRows];

        final float cx = data.getCameraParameters().getCenter().x();
        final float cy = data.getCameraParameters().getCenter().y();
        final float fx = data.getCameraParameters().getFocalLength().x();
        final float fy = data.getCameraParameters().getFocalLength().y();

        final float k1 = data.getCameraParameters().getCorrection().getK1();
        final float k2 = data.getCameraParameters().getCorrection().getK2();
        final float f2rc = data.getCameraParameters().getFocalToRayCross();

        IMatrix4f cameraToWorldMatrix = data.getCameraParameters().getCameraToWorldMatrix();

        // transform each pixel into Cartesian coordinates
        int pIndex = 0;
        for (int row = 0; row < numRows; row++)
        {
            for (int col = 0; col < numCols; col++)
            {
                final int depth = distanceMap[col][row];

                // we map from image coordinates with origin top left and x
                // horizontal (right) and y vertical
                // (downwards) to camera coordinates with origin in center and x
                // to the left and y upwards (seen
                // from the sensor position)
                final double xp = (cx - col) / fx;
                final double yp = (cy - row) / fy;

                // correct the camera distortion
                final double r2 = xp * xp + yp * yp;
                final double r4 = r2 * r2;
                final double k = 1 + k1 * r2 + k2 * r4;
                final double xd = xp * k;
                final double yd = yp * k;

                final double s0 = Math.sqrt(xd * xd + yd * yd + 1.0);

                final float x = (float) (xd * depth / s0);
                final float y = (float) (yd * depth / s0);
                final float z = (float) (depth / s0 - f2rc);

                // transform points from camera space into world space
                IVector3f xyz = cameraToWorldMatrix.transform(Vector3f.xyz(x, y, z));
                pointCloud[0][pIndex] = xyz.x();
                pointCloud[1][pIndex] = xyz.y();
                pointCloud[2][pIndex] = xyz.z();
                pIndex++;
            }
        }
        return pointCloud;
    }

    /**
     * saves the point cloud data to disk into a file. For more details, see
     * {@link <a href="http://pointclouds.org/documentation/tutorials/pcd_file_format.php">The PCD (Point Cloud Data) file format</a>}
     * .
     *
     * The input point cloud must be a two-dimensional array with the following structure:
     *
     * <pre>
     * {
     *     double[][] pointCloud = new double[3][num_of_points];
     *     double x = pointCloud[0][i];
     *     double y = pointCloud[1][i];
     *     double z = pointCloud[2][i];
     * }
     * </pre>
     *
     * @param pointCloud point cloud data
     * @param path A pathname string.
     */
    public static void savePointCloudAsPCDFile(double[][] pointCloud, String path)
    {
        File file = new File(path);
        try
        {
            if (!file.exists())
            {
                file.createNewFile();
            }
            StringBuffer buffer = new StringBuffer();

            // create .PCD Header
            buffer.append("# .PCD v0.7 - Point Cloud Data file format\n");
            buffer.append("VERSION 0.7\n");
            buffer.append("FIELDS x y z\n");
            buffer.append("SIZE 4 4 4\n");
            buffer.append("TYPE F F F\n");
            buffer.append("COUNT 1 1 1\n");
            buffer.append("WIDTH " + pointCloud[0].length + "\n");
            buffer.append("HEIGHT 1\n");
            buffer.append("VIEWPOINT 0 0 0 1 0 0 0\n");
            buffer.append("POINTS " + pointCloud[0].length + "\n");
            buffer.append("DATA ascii\n");

            BufferedWriter writer = new BufferedWriter(new FileWriter(file));
            writer.write(buffer.toString());

            for (int i = 0; i < pointCloud[0].length; i++)
            {
                String line =
                    String.format(Locale.ENGLISH, "%.4f %.4f %.4f%n", pointCloud[0][i], pointCloud[1][i],
                        pointCloud[2][i]);
                writer.write(line);
            }

            writer.flush();
            writer.close();
        }
        catch (IOException e)
        {
            // some issue with file output
            e.printStackTrace();
        }
    }

    /**
     * Saves the 2d array as an .PNG image to disk into a file.
     *
     * @param map
     * @param path
     * @param minValue
     * @param maxValue
     */
    static void saveMapToImage(int[][] map, String path, int minValue, int maxValue)
    {
        int numRows = map[0].length;
        int numCols = map.length;

        BufferedImage bi = new BufferedImage(numCols, numRows, BufferedImage.TYPE_INT_RGB);
        WritableRaster wr = bi.getRaster();

        for (int row = 0; row < numRows; row++)
        {
            for (int col = 0; col < numCols; col++)
            {
                final int depth = map[col][row];
                wr.setPixel(col, row, getColor(depth, minValue, maxValue));
            }
        }

        try
        {
            File outputfile = new File(path);
            ImageIO.write(bi, "png", outputfile);
        }
        catch (IOException e)
        {
        	// some issue with file output
            e.printStackTrace();
        }
    }

    /**
     * Return a RGB color value given a scalar v in the range [vmin,vmax] In this case each colour component ranges from 0
     * (no contribution) to 255 (fully saturated), modifications for other ranges is trivial. The color is clipped at the
     * end of the scales if v is outside the range [vmin,vmax]. <br>
     * <b>Source:</b> {@link <a href="http://paulbourke.net/texture_colour/colourspace/">RGB colour space</a>}
     *
     * @return int array with RGB values {r,g,b}
     */
    public static int[] getColor(int v, int vmin, int vmax)
    {
        // white
        int r = 255;
        int g = 255;
        int b = 255;

        float dv;

        if (v < vmin)
        {
            v = vmin;
        }
        if (v > vmax)
        {
            v = vmax;
        }
        dv = vmax - vmin;

        if (v < (vmin + 0.25 * dv))
        {
            r = 0;
            g = (int) (255 * (4 * (v - vmin) / dv));
        }
        else if (v < (vmin + 0.5 * dv))
        {
            r = 0;
            b = (int) (255 * (1 + 4 * (vmin + 0.25 * dv - v) / dv));
        }
        else if (v < (vmin + 0.75 * dv))
        {
            r = (int) (255 * (4 * (v - vmin - 0.5 * dv) / dv));
            b = 0;
        }
        else
        {
            g = (int) (255 * (1 + 4 * (vmin + 0.75 * dv - v) / dv));
            b = 0;
        }

        return new int[]
        {r, g, b};
    }
}
