import ij.plugin.*;
import ij.*;
import ij.gui.*;
import ij.process.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import javax.swing.*; 
import javax.imageio.ImageIO;
import java.io.*;

public class Mitochondria_Analyzer implements PlugIn, ActionListener 
{ 

   boolean mainMode=false;
   //Specifies where images (e.g. logo) are stored in JAR file
   String imagePath = "/Resources/";
   //Specifies where macros are stored
   String path = "/Macros/";
   InputStream is;

   public void run(String arg) 
   { 
       //Load up logo, and use it to check if in JAR compilation or not
       is = getClass().getResourceAsStream(imagePath + "MitoAnalyzer_Logo.png");
       if (is==null) imagePath = "D:/Ahsen/Desktop/Mitochondria Analyzer/Resources/";
       //if (is==null) imagePath = System.getProperty("user.dir") + "/plugins/MitochondriaAnalyzer/Resources/";
       
       path = System.getProperty("user.dir") + "/plugins/MitochondriaAnalyzer/Macros/";

       if (arg.equals("2D Threshold Optimize")) ThresholdOptimize2D();
       if (arg.equals("3D Threshold Optimize")) ThresholdOptimize3D();
       if (arg.equals("2D Threshold")) Threshold2D();
       if (arg.equals("3D Threshold")) Threshold3D();
       if (arg.equals("2D Analysis")) Analysis2D();
       if (arg.equals("3D Analysis")) Analysis3D();
       if (arg.equals("2D Batch")) Batch2D();
       if (arg.equals("3D Batch")) Batch3D();
       if (arg.equals("Display 2D Mito ROI")) Display2DMitoROI();
       if (arg.equals("Display 3D Mito ROI")) Display3DMitoROI();
       if (arg.equals("2D TimeLapse Threshold")) TimeLapseThreshold2D();
       if (arg.equals("2D TimeLapse Analysis")) TimeLapseAnalysis2D();
       if (arg.equals("3D TimeLapse Threshold")) TimeLapseThreshold3D();
       if (arg.equals("3D TimeLapse Analysis")) TimeLapseAnalysis3D();
       
	   if (arg.equals("") || arg.equals("run"))
	   {
	   	   mainMode=true;
	   	   
	       //Creates Main Panel
	   	   JFrame mainframe = new JFrame("Mitochondria Analyzer");
	   	   mainframe.setSize(400,450);
	   	   mainframe.setLayout(new BorderLayout());
	   	   mainframe.setResizable(false);
	
	       //Add buttons and logo
	       JPanel buttonsPanel = MakeButtonsPanel();
	       JLabel logo = MakeLogo();
	
		   mainframe.add(logo,BorderLayout.PAGE_START);
		   mainframe.add(buttonsPanel,BorderLayout.CENTER);
		   mainframe.pack();
		   mainframe.setVisible(true);
		   
	   }
   } 


   public JPanel MakeButtonsPanel()
   {
   	   JPanel panel = new JPanel(new GridBagLayout());
   	   
       GridBagConstraints c = new GridBagConstraints();
       c.fill = GridBagConstraints.HORIZONTAL;
       c.anchor = GridBagConstraints.PAGE_START;
       c.weightx = 0.5;
       c.insets = new Insets(1,5,1,5);

       c.gridx=0; c.gridy=0;
       panel.add(new JLabel("2D Commands",JLabel.CENTER ),c);
       c.gridx=1; c.gridy=0;
       panel.add(new JLabel("3D Commands",JLabel.CENTER ),c);
       
       JButton button1 = new JButton("2D Threshold Optimize");
       button1.addActionListener(this);      
       c.gridx=0; c.gridy=1;
       panel.add(button1,c);

       JButton button2 = new JButton("3D Threshold Optimize");
       button2.addActionListener(this);       
       c.gridx=1; c.gridy=1;
       panel.add(button2,c);

       JButton button3 = new JButton("2D Threshold");
       button3.addActionListener(this);        
	   c.gridx=0; c.gridy=2;
       panel.add(button3,c);

       JButton button4 = new JButton("3D Threshold");
       button4.addActionListener(this);     
	   c.gridx=1; c.gridy=2;
       panel.add(button4,c);

       JButton button5 = new JButton("2D Analysis");
       button5.addActionListener(this);      
	   c.gridx=0; c.gridy=3;
       panel.add(button5,c);

       JButton button6 = new JButton("3D Analysis");
       button6.addActionListener(this);        
	   c.gridx=1; c.gridy=3;
       panel.add(button6,c);

       JButton button7 = new JButton("2D Batch Commands");
       button7.addActionListener(this);      
	   c.gridx=0; c.gridy=4; 
       panel.add(button7,c);

       JButton button8 = new JButton("3D Batch Commands");
       button8.addActionListener(this);     
	   c.gridx=1; c.gridy=4;
       panel.add(button8,c);

       JButton button9 = new JButton("Display 2D Mito ROIs");
       button9.addActionListener(this);    
	   c.gridx=0; c.gridy=5;
       panel.add(button9,c);

       JButton button10 = new JButton("Display 3D Mito ROIs");
       button10.addActionListener(this);  	
       c.gridx=1; c.gridy=5;
       panel.add(button10,c);
       
       c.gridx=0; c.gridy=6;
       c.gridwidth=2;
       panel.add(new JLabel(" ",JLabel.CENTER ),c);
       c.gridwidth=1; 
       c.gridx=0; c.gridy=7;
       panel.add(new JLabel("2D TimeLapse (xyt)",JLabel.CENTER ),c);
       c.gridx=1; c.gridy=7;
       panel.add(new JLabel("3D TimeLapse (4D - xyzt)",JLabel.CENTER ),c);

       JButton button11 = new JButton("2D TimeLapse Threshold");
       button11.addActionListener(this);       
	   c.gridx=0; c.gridy=8; 
       panel.add(button11,c);

       JButton button12 = new JButton("3D TimeLapse Threshold");
       button12.addActionListener(this);    
	   c.gridx=1; c.gridy=8;
       panel.add(button12,c);

       JButton button13 = new JButton("2D TimeLapse Analysis");
       button13.addActionListener(this);        
	   c.gridx=0; c.gridy=9;
       panel.add(button13,c);

       JButton button14 = new JButton("3D TimeLapse Analysis");
       button14.addActionListener(this);        
	   c.gridx=1; c.gridy=9;
       panel.add(button14,c);
       
       c.gridx=0; c.gridy=10;
       c.gridwidth=2;
       panel.add(new JLabel(" ",JLabel.CENTER ),c);
       c.gridwidth=1;
       
   	   return panel;
   }

   public JLabel MakeLogo()
   {
  	   BufferedImage image = null;

 	   try 
 	   {           
 	   	  if (is!=null) image = ImageIO.read(is);
 	   	  if (is==null) image = ImageIO.read(new File(imagePath + "MitoAnalyzer_Logo.png"));
 	   } 
   	   catch (IOException ex) 
       {
            IJ.showMessage("Error", ex.getMessage());
       }
       
       BufferedImage myPicture = image; 
	   JLabel picLabel = new JLabel(new ImageIcon(myPicture));
	   
   	   return picLabel;
   }

   public void actionPerformed(ActionEvent e) 
   { 
       String name = e.getActionCommand(); 
       if (name.equals("2D Threshold Optimize"))  ThresholdOptimize2D();
       if (name.equals("3D Threshold Optimize")) ThresholdOptimize3D();
       if (name.equals("2D Threshold")) Threshold2D();
       if (name.equals("3D Threshold")) Threshold3D();
       if (name.equals("2D Analysis")) Analysis2D();
       if (name.equals("3D Analysis")) Analysis3D();
       if (name.equals("2D Batch Commands")) Batch2D();
       if (name.equals("3D Batch Commands")) Batch3D();
       if (name.equals("Display 2D Mito ROIs")) Display2DMitoROI();
       if (name.equals("Display 3D Mito ROIs")) Display3DMitoROI();       
       if (name.equals("2D TimeLapse Threshold")) TimeLapseThreshold2D();
       if (name.equals("2D TimeLapse Analysis")) TimeLapseAnalysis2D();
       if (name.equals("3D TimeLapse Threshold")) TimeLapseThreshold3D();
       if (name.equals("3D TimeLapse Analysis")) TimeLapseAnalysis3D();
    }

//System.getProperty("plugins.dir")
    public void Threshold2D()
    {
    	run_Macro( "2DThreshold.ijm");
    }
    public void Threshold3D()
    {
    	run_Macro( "3DThreshold.ijm");
    }
    public void Analysis2D()
    {
    	run_Macro( "2DAnalysis.ijm");
    }
    public void Analysis3D()
    {
    	run_Macro( "3DAnalysis.ijm");
    }
    public void Batch2D()
    {
    	run_Macro( "2DBatch.ijm");
    }
    public void Batch3D()
    {
    	run_Macro( "3DBatch.ijm");
    }
    public void Display2DMitoROI()
    {
    	run_Macro( "Display2DMitoROI.ijm");
    }
    public void Display3DMitoROI()
    {
    	run_Macro( "Display3DMitoROI.ijm");
    }
    public void ThresholdOptimize2D()
    {
    	run_Macro( "2DThresholdOptimize.ijm");
    }
    public void ThresholdOptimize3D()
    {
    	run_Macro( "3DThresholdOptimize.ijm");
    }
    public void TimeLapseThreshold2D()
    {
    	run_Macro( "2DTimeLapseThreshold.ijm");
    }
    public void TimeLapseAnalysis2D()
    {
    	run_Macro( "2DTimeLapseAnalysis.ijm");
    }
    public void TimeLapseThreshold3D()
    {
    	run_Macro( "3DTimeLapseThreshold.ijm");
    }
    public void TimeLapseAnalysis3D()
    {
    	run_Macro( "3DTimeLapseAnalysis.ijm");
    }

    public void run_Macro (String macroName)
    {
    	if (mainMode==true)
    	{
	 		 new Thread(() -> 
	 		 {
	              IJ.runMacroFile(path + macroName);
	         }).start();
    	}
    	else IJ.runMacroFile(path + macroName);
    }

} 
