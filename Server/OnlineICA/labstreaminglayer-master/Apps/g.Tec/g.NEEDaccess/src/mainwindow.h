#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QMutex>
#include "lsl_cpp.h"
#include "GDSClientAPI.h"

const QString default_config_fname = "gneedaccess_config.cfg";

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0,
		const QString config_file = default_config_fname);
    ~MainWindow();

signals:
	void dataReady(void);

private slots:
	// GUI
	void on_loadConfigPushButton_clicked();
	void on_saveConfigPushButton_clicked();
	void on_scanPushButton_clicked();
	void on_devCfgPushButton_clicked();
	void on_connectPushButton_clicked();
    void on_goPushButton_clicked();
	void on_availableListWidget_itemSelectionChanged();
	void notify_samples_pushed();

private:
	struct filter_type {
		enum eFilterClass { bandpass, highpass, lowpass, notch };
		enum eFilterType { FIR, IIR, Analog, Unknown };
		eFilterClass filter_class = bandpass;
		eFilterType type = Unknown;
		std::string design = "Unknown";
		double lower = 0;
		double upper = 0;
		int order = 0;
	};
	struct chan_info_type {
		bool enabled;
		std::string label;
		std::string type;
		std::string unit;
		int reference = -1;
		double impedance = -1;
		double scaling_offset = 0.0;
		double scaling_factor = 1.0;
		std::vector<filter_type> filtering;
	};
	struct dev_info_type {
		std::string name;
		size_t nsamples_per_scan = 0;  // == number of channels in a data frame (I think)
		size_t scans_per_block = 0;
		double nominal_srate = lsl::IRREGULAR_RATE;
		lsl::channel_format_t channel_format = lsl::cf_float32;
		std::vector<chan_info_type> channel_infos;
	};

	// Static methods
	static bool handleResult(std::string calling_func, GDS_RESULT ret);
	static void dataReadyCallback(GDS_HANDLE connectionHandle, void* usrData);
	
	// Private methods
    void load_config(const QString filename);
    void save_config(const QString filename);
	bool do_connect();
	bool get_connected_devices_configs();
	void clear_dev_configs();

	// private members
    Ui::MainWindow *ui;
	QMutex mutex;
	QTimer* m_pTimer;			// The timer will be started when Go is clicked. Whenever it times out, the status bar will be updated with the number of samples pushed.
	bool m_bConnected = false;
	bool m_bStreaming = false;
	size_t m_samplesPushed = 0;
	std::vector<std::string> m_chanLabels;  // g.HIamp and g.USBamp do not store channel names, so we need to manage them via config file.
	std::vector<double> m_chanImpedances;  // TODO: Use GDS_GNAUTILUS_GetImpedance, GDS_GUSBAMP_GetImpedance

	// GDS communication
	GDS_ENDPOINT m_hostEndpoint = { "127.0.0.1", 50223 };
	GDS_ENDPOINT m_localEndpoint = { "127.0.0.1", 50224 };
	std::vector<GDS_CONFIGURATION_BASE> m_devConfigs;
	GDS_HANDLE m_connectionHandle = 0;
	bool m_isCreator = false;
	
	// LSL variables
	dev_info_type m_devInfo;
	std::vector<float> m_dataBuffer = {};
	lsl::stream_outlet* m_eegOutlet;
};

#endif // MAINWINDOW_H
