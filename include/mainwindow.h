#pragma once

#include "utils.h"
#include "gridview.h"

#include <QAction>
#include <QActionGroup>
#include <QColor>
#include <QJsonObject>
#include <QLabel>
#include <QMainWindow>
#include <QMouseEvent>
#include <QPaintEvent>
#include <QPixmap>
#include <QPushButton>
#include <QResizeEvent>
#include <QSettings>
#include <QTableWidget>
#include <QVector>
#include <QWidget>
#include <QProcess>
#include <cmath>

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_actionQuit_triggered();
    void on_actionSave_JSON_triggered();
    void on_actionGitHub_triggered();
    void on_actionAbout_QDiskInfo_triggered();
    void on_actionAbout_Qt_triggered();
    void on_actionRescan_Refresh_triggered();
    void on_actionIgnore_C4_Reallocation_Event_Count_toggled(bool enabled);
    void on_actionHEX_toggled(bool enabled);
    void on_actionUse_Fahrenheit_toggled(bool enabled);
    void on_actionCyclic_Navigation_toggled(bool arg1);
    void on_actionUse_GB_instead_of_TB_toggled(bool arg1);

    void on_actionClear_Settings_triggered();

    void on_actionASCII_View_triggered();

    void on_actionGrid_View_triggered();

    void on_actionSave_Image_triggered();

private:
    Ui::MainWindow *ui;
    QSettings settings;
    bool initializing;
    QLocale locale;
    utils Utils;
    QButtonGroup *buttonGroup;
    QHBoxLayout *horizontalLayout;
    QVBoxLayout *verticalLayout;
    QGridLayout *gridLayout;
    QLabel *diskName, *temperatureValue, *healthStatusValue;
    QLabel *temperatureLabelHorizontal, *healthStatusLabelHorizontal, *temperatureValueHorizontal, *healthStatusValueHorizontal;
    QLineEdit *firmwareLineEdit, *serialNumberLineEdit, *typeLineEdit, *protocolLineEdit, *deviceNodeLineEdit;
    QLineEdit *totalReadsLineEdit, *totalWritesLineEdit, *rotationRateLineEdit, *powerOnCountLineEdit, *powerOnHoursLineEdit;
    QTableWidget *tableWidget;
    QPushButton *prevButton, *nextButton;
    QColor goodColor, cautionColor, badColor, naColor;
    QLabel *statusLabel;
    QJsonObject deviceJson;
    QSpacerItem *buttonStretch;
    QAction *actionCyclic_Navigation;
    QMenu *menuDevice;
    QMenu *menuDisk;
    QMenu *selfTestMenu;
    QAction *selfTestLogAction;
    QActionGroup *disksGroup;
    QJsonArray devices;
    QStringList deviceOutputs;
    QJsonObject globalObj;
    QString globalHealth;
    bool globalIsNvme;
    QVector<QPair<QString, int>> globalNvmeSmartOrdered;
    GridView *gridView;

    void onNextButtonClicked();
    void onPrevButtonClicked();
    void updateNavigationButtons(qsizetype currentIndex);
    void updateUI(const QString &currentDeviceName = QString());
    void populateWindow(const QJsonObject &tempObj, const QString &health, const QVector<QPair<QString, int>>& nvmeLogOrdered = QVector<QPair<QString, int>>());
    void addSCSIErrorCounterLogTable(const QJsonObject &scsiErrorCounterLog);
    void addNvmeLogTable(const QVector<QPair<QString, int>>& nvmeLogOrdered);
    void addSmartAttributesTable(const QJsonArray &attributes);
    void transformWindow();

protected:
    void mousePressEvent(QMouseEvent*) override;
    void paintEvent(QPaintEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    struct AoiTheme {
        QString name;
        QString dirPath;
        QString backgroundPath;
        bool isDark = false;
        QColor labelText = Qt::black;
        QColor listText = Qt::black;
        QColor listBg1 = QColor(0xFF, 0xFF, 0xFF);
        QColor listBg2 = QColor(0xF8, 0xF8, 0xF8);
        QColor listLine = QColor(0xE0, 0xE0, 0xE0);
        QColor glassColor = QColor(0xFF, 0xFF, 0xFF);
        int glassAlpha = 128;
        int characterPosition = 1; // 1 = right, 0 = left
    };

    bool themeEnabled = false;
    QVector<AoiTheme> availableThemes;
    AoiTheme currentTheme;
    QString aoiBaseThemeDir;
    QMenu *menuTheme = nullptr;
    QActionGroup *themeActionGroup = nullptr;
    QAction *randomThemeAction = nullptr;
    QWidget *characterSpacer = nullptr;
    QPixmap currentBackgroundPixmap;
    QPixmap cachedScaledBackground;
    QSize cachedBackgroundSize;
    qreal cachedBackgroundDpr = 0.0;
    QString currentHealth;
    QString currentPercentage;

    void initThemes();
    QStringList themeSearchDirs() const;
    AoiTheme parseThemeIni(const QString &themeName, const QString &dirPath, const QString &bgPath) const;
    void setupThemeMenu();
    void applyTheme(const QString &themeName);
    void selectRandomTheme(bool avoidCurrent = false);
    void updateStatusSprite();

    QString mbSymbol;
    QString gbSymbol;
    QString tbSymbol;
    QString pbSymbol;
    QString getMbToPrettyString(const int64_t &sizeInMbI64, const int &precisionInt, const bool &useGbBool) const;
};
