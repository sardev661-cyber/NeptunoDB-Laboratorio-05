using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace NeptunoLab05
{
    public sealed class Field
    {
        public string Name, Label, Kind; public int Size; public bool Required;
        public Field(string name, string label, string kind, int size, bool required)
        { Name = name; Label = label; Kind = kind; Size = size; Required = required; }
    }
    public sealed class Entity
    {
        public string Name, Key; public Field[] Fields;
        public Entity(string name, string key, params Field[] fields) { Name = name; Key = key; Fields = fields; }
    }
    public static class Program
    {
        [STAThread]
        public static void Main(string[] args)
        {
            try {
                FrameworkElement.LanguageProperty.OverrideMetadata(typeof(FrameworkElement), new FrameworkPropertyMetadata(XmlLanguage.GetLanguage(CultureInfo.CurrentCulture.IetfLanguageTag)));
                new Application().Run(new Shell(args).Window);
            }
            catch (Exception ex) { MessageBox.Show(ex.Message, "Neptuno", MessageBoxButton.OK, MessageBoxImage.Error); }
        }
    }
    public sealed class Shell
    {
        public Window Window; public DataAccess Db; public DataSet Catalogs;
        public bool Preview; private TabControl tabs; private TextBlock status;
        private readonly List<CrudView> views = new List<CrudView>();
        private SearchView search; private ReportView report; private string capturePath;
        public Shell(string[] args)
        {
            Preview = args.Contains("--vista-previa") || args.Contains("--capturas");
            var index = Array.IndexOf(args, "--capturas");
            if (index >= 0) capturePath = index + 1 < args.Length ? Path.GetFullPath(args[index+1]) : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Capturas");
            using (var stream = File.OpenRead(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "MainWindow.xaml")))
                Window = (Window)XamlReader.Load(stream);
            tabs = (TabControl)Window.FindName("MainTabs"); status = (TextBlock)Window.FindName("GlobalStatus");
            foreach (var entity in Schema.Entities)
            { var view = new CrudView(this, entity); views.Add(view); tabs.Items.Add(new TabItem { Header = entity.Name, Content = view.Root }); }
            search = new SearchView(this); report = new ReportView(this);
            tabs.Items.Add(new TabItem { Header = "Buscar proveedores", Content = search.Root });
            tabs.Items.Add(new TabItem { Header = "Reporte por fechas", Content = report.Root });
            tabs.SelectionChanged += delegate(object sender, SelectionChangedEventArgs e)
            { if (e.Source == tabs && Db != null) Run(RefreshSelected); };
            Window.Loaded += delegate {
                if (Preview) { LoadPreview(); if (capturePath != null) Capture(0); }
                else Connect();
            };
        }
        private void Connect()
        {
            Run(delegate {
                var configured = ConfigurationManager.ConnectionStrings["Neptuno"];
                if (configured == null || string.IsNullOrWhiteSpace(configured.ConnectionString))
                    throw new ConfigurationErrorsException("No se encontró la cadena de conexión Neptuno en App.config.");
                status.Text = "Conectando con SQL Server…";
                var candidate = new DataAccess(configured.ConnectionString);
                var catalogs = candidate.Catalogs(); // Solo sustituir la conexión después de validarla.
                Db = candidate; Catalogs = catalogs; Preview = false;
                foreach (var v in views) v.SetCatalogs(Catalogs);
                Refresh(); status.Text = "Conexión activa · Se muestran únicamente registros activos.";
            });
        }
        public void Run(Action action)
        {
            try { action(); }
            catch (Exception ex) { status.Text = "Error: " + ex.Message; MessageBox.Show(Window, ex.Message, "Revise la operación", MessageBoxButton.OK, MessageBoxImage.Warning); }
        }
        public void RequireDb()
        { if (Preview || Db == null) throw new InvalidOperationException("Conecte a SQL Server para consultar o modificar datos. La vista previa no ejecuta SQL."); }
        public void Refresh()
        {
            RequireDb(); Catalogs = Db.Catalogs(); foreach (var v in views) { v.SetCatalogs(Catalogs); v.Load(); }
            search.Load(); report.Load();
        }
        private void RefreshSelected()
        {
            RequireDb();
            if (tabs.SelectedIndex >= 0 && tabs.SelectedIndex < views.Count)
            {
                Catalogs = Db.Catalogs(); foreach (var v in views) v.SetCatalogs(Catalogs);
                views[tabs.SelectedIndex].Load();
            }
            else if (tabs.SelectedIndex == views.Count) search.Load();
            else if (tabs.SelectedIndex == views.Count + 1) report.Load();
        }
        public void Refresh(CrudView view)
        {
            RequireDb(); Catalogs = Db.Catalogs(); foreach (var v in views) v.SetCatalogs(Catalogs); view.Load();
        }
        public void Notify(string message) { status.Text = message; }
        private void LoadPreview()
        {
            var ds = PreviewData.Create();
            Catalogs = new DataSet(); foreach (var n in new[] { "Categorias", "Proveedores", "Clientes", "Empleados", "Transportistas" })
            {
                var t = new DataTable(); t.Columns.Add("ID", typeof(int)); t.Columns.Add("Nombre");
                foreach (DataRow row in ds.Tables[n].Rows) t.Rows.Add(row[0], row[1]); Catalogs.Tables.Add(t);
            }
            foreach (var v in views) { v.SetCatalogs(Catalogs); v.SetData(ds.Tables[v.Entity.Name]); }
            search.SetData(ds.Tables["Proveedores"]); report.SetData(ds.Tables["Reporte"]);
            status.Text = "VISTA PREVIA · Datos del script suministrado. Esta captura no acredita ejecución ni conexión a SQL Server.";
        }
        private void Capture(int index)
        {
            if (index >= tabs.Items.Count) { Window.Close(); return; }
            tabs.SelectedIndex = index;
            Window.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, new Action(delegate {
                Window.UpdateLayout(); var surface = (FrameworkElement)Window.Content;
                var bitmap = new RenderTargetBitmap((int)surface.ActualWidth, (int)surface.ActualHeight, 96, 96, PixelFormats.Pbgra32);
                bitmap.Render(surface); var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
                Directory.CreateDirectory(capturePath);
                using (var fs = File.Create(Path.Combine(capturePath, (index + 1).ToString("00") + ".png"))) encoder.Save(fs);
                Capture(index + 1);
            }));
        }
    }
    public static class Ui
    {
        public static Button Button(string text, Action action, string style)
        { var b = new Button { Content = text }; if (style != null) b.SetResourceReference(FrameworkElement.StyleProperty, style); b.Click += delegate { action(); }; return b; }
        public static Button Button(string text, Action action) { return Button(text, action, null); }
        public static TextBlock Title(string text)
        { return new TextBlock { Text = text, FontSize = 23, Foreground = new SolidColorBrush(Color.FromRgb(21,34,56)), FontWeight = FontWeights.SemiBold, Margin = new Thickness(0,0,0,12) }; }
        public static FrameworkElement Labeled(string label, FrameworkElement input, double width)
        { var p = new StackPanel { Width = width, Margin = new Thickness(0,0,16,12) }; p.Children.Add(new TextBlock { Text = label, Foreground = new SolidColorBrush(Color.FromRgb(71,85,105)), FontWeight = FontWeights.SemiBold, Margin = new Thickness(0,0,0,5) }); p.Children.Add(input); return p; }
        public static DataGrid Grid() {
            var grid = new DataGrid { AutoGenerateColumns = true, Margin = new Thickness(0,10,0,0) };
            grid.AutoGeneratingColumn += delegate(object sender, DataGridAutoGeneratingColumnEventArgs e) {
                var col = e.Column as DataGridTextColumn;
                if (col != null) {
                    var binding = col.Binding as System.Windows.Data.Binding;
                    if (binding != null && e.PropertyType == typeof(DateTime)) binding.StringFormat = "dd/MM/yyyy";
                    if (binding != null && e.PropertyType == typeof(decimal)) binding.StringFormat = "N2";
                }
            }; return grid;
        }
    }
    public sealed class CrudView
    {
        public Entity Entity; public DockPanel Root; private Shell shell; private DataGrid grid;
        private Dictionary<string, FrameworkElement> inputs = new Dictionary<string, FrameworkElement>(); private int? selected;
        private TextBlock selection;
        public CrudView(Shell shell, Entity entity)
        {
            this.shell = shell; Entity = entity; Root = new DockPanel { Margin = new Thickness(18) };
            var top = new StackPanel(); DockPanel.SetDock(top, Dock.Top); Root.Children.Add(top);
            top.Children.Add(Ui.Title("Mantenimiento de " + entity.Name.ToLower()));
            selection = new TextBlock { Text = "Nuevo registro · * Campo obligatorio", Margin = new Thickness(0,0,0,10) }; top.Children.Add(selection);
            var form = new WrapPanel(); top.Children.Add(form);
            foreach (var f in entity.Fields)
            {
                FrameworkElement control;
                if (f.Kind == "lookup") control = new ComboBox { DisplayMemberPath = "Nombre", SelectedValuePath = "ID" };
                else if (f.Kind == "date") control = new DatePicker();
                else if (f.Kind == "bit") control = new CheckBox { Content = "Sí", VerticalAlignment = VerticalAlignment.Center, Height = 30 };
                else control = new TextBox { MaxLength = f.Size > 0 ? f.Size : 16 };
                inputs.Add(f.Name, control); form.Children.Add(Ui.Labeled(f.Label + (f.Required ? " *" : ""), control, 240));
            }
            var buttons = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0,3,0,4) };
            buttons.Children.Add(Ui.Button("Nuevo / limpiar", Clear));
            buttons.Children.Add(Ui.Button("Insertar", delegate { shell.Run(delegate { Save(true); }); }, "PrimaryButton"));
            buttons.Children.Add(Ui.Button("Actualizar", delegate { shell.Run(delegate { Save(false); }); }));
            buttons.Children.Add(Ui.Button("Eliminar", delegate { shell.Run(Delete); }, "DangerButton"));
            buttons.Children.Add(Ui.Button("Recargar", delegate { shell.Run(delegate { shell.Refresh(this); }); })); top.Children.Add(buttons);
            grid = Ui.Grid(); grid.SelectionChanged += delegate { Select(); }; Root.Children.Add(grid); Clear();
        }
        public void SetData(DataTable table) { grid.ItemsSource = table.DefaultView; }
        public void Load() { SetData(shell.Db.Read("dbo.usp_"+Entity.Name+"_Listar")); Clear(); }
        public void SetCatalogs(DataSet ds)
        {
            var positions = new Dictionary<string,int> { {"CategoriaID",0},{"ProveedorID",1},{"ClienteID",2},{"EmpleadoID",3},{"TransportistaID",4} };
            foreach (var f in Entity.Fields.Where(x => x.Kind == "lookup"))
            {
                var cb = (ComboBox)inputs[f.Name]; object old = cb.SelectedValue;
                var table = ds.Tables[positions[f.Name]].Copy(); var blank = table.NewRow(); blank["Nombre"] = "(Sin asignar)"; table.Rows.InsertAt(blank,0);
                cb.ItemsSource = table.DefaultView; cb.SelectedValue = old;
            }
        }
        private void Clear()
        {
            selected = null; if (grid != null) grid.SelectedItem = null; selection.Text = "Nuevo registro · * Campo obligatorio";
            foreach (var f in Entity.Fields)
            {
                var c = inputs[f.Name];
                if (c is TextBox) ((TextBox)c).Text = f.Kind == "decimal" || f.Kind == "smallint" ? "0" : "";
                if (c is ComboBox) ((ComboBox)c).SelectedIndex = 0;
                if (c is DatePicker) ((DatePicker)c).SelectedDate = f.Required ? (DateTime?)DateTime.Today : null;
                if (c is CheckBox) ((CheckBox)c).IsChecked = false;
            }
        }
        private void Select()
        {
            var row = grid.SelectedItem as DataRowView; if (row == null) return;
            selected = Convert.ToInt32(row[Entity.Key]); selection.Text = Entity.Key + " = " + selected + " · Registro activo seleccionado";
            foreach (var f in Entity.Fields)
            {
                var c=inputs[f.Name]; var value=row[f.Name];
                if (c is TextBox) ((TextBox)c).Text = value == DBNull.Value ? "" : Convert.ToString(value, CultureInfo.CurrentCulture);
                if (c is ComboBox) ((ComboBox)c).SelectedValue = value;
                if (c is DatePicker) ((DatePicker)c).SelectedDate = value == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(value);
                if (c is CheckBox) ((CheckBox)c).IsChecked = value != DBNull.Value && Convert.ToBoolean(value);
            }
        }
        private SqlParameter Parameter(Field f)
        {
            var c=inputs[f.Name]; object value=DBNull.Value; SqlDbType type=SqlDbType.NVarChar;
            if (f.Kind == "text") { value=((TextBox)c).Text.Trim(); if ((string)value == "") value=DBNull.Value; }
            if (f.Kind == "lookup") { type=SqlDbType.Int; value=((ComboBox)c).SelectedValue ?? DBNull.Value; }
            if (f.Kind == "date") { type=SqlDbType.Date; value=(object)((DatePicker)c).SelectedDate ?? DBNull.Value; }
            if (f.Kind == "bit") { type=SqlDbType.Bit; value=((CheckBox)c).IsChecked == true; }
            if (f.Kind == "smallint")
            {
                type=SqlDbType.SmallInt; short n;
                if (!short.TryParse(((TextBox)c).Text, out n) || n < 0) throw new ArgumentException(f.Label+": use un entero entre 0 y 32767."); value=n;
            }
            if (f.Kind == "decimal")
            {
                type=SqlDbType.Decimal; decimal n;
                if (!decimal.TryParse(((TextBox)c).Text, NumberStyles.AllowDecimalPoint | NumberStyles.AllowLeadingSign, CultureInfo.CurrentCulture, out n) || n < 0 || n > 99999999.99m || decimal.Round(n,2) != n)
                    throw new ArgumentException(f.Label+": use un valor entre 0 y 99999999,99 con máximo dos decimales. Separador local: "+CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator);
                value=n;
            }
            if (f.Required && value == DBNull.Value) throw new ArgumentException(f.Label+" es obligatorio.");
            var p=new SqlParameter("@"+f.Name,type) { Value=value }; if(f.Size>0) p.Size=f.Size;
            if(type==SqlDbType.Decimal) { p.Precision=10; p.Scale=2; } return p;
        }
        private void Save(bool insert)
        {
            shell.RequireDb(); if (!insert && !selected.HasValue) throw new InvalidOperationException("Seleccione el registro que desea actualizar.");
            if (insert && selected.HasValue) throw new InvalidOperationException("Pulse Nuevo / limpiar antes de insertar un registro.");
            var parameters=Entity.Fields.Select(Parameter).ToList();
            if (!insert) parameters.Insert(0,new SqlParameter("@"+Entity.Key,SqlDbType.Int) { Value=selected.Value });
            int id=shell.Db.Write("dbo.usp_"+Entity.Name+(insert ? "_Insertar" : "_Actualizar"),insert,parameters.ToArray());
            shell.Refresh(this); shell.Notify(insert ? "Registro insertado. ID generado: "+id : "Registro actualizado correctamente.");
        }
        private void Delete()
        {
            shell.RequireDb(); if (!selected.HasValue) throw new InvalidOperationException("Seleccione un registro para darlo de baja.");
            if (MessageBox.Show("¿Dar de baja el registro "+selected+"? Se conservará en la base con Activo = 0.","Confirmar baja lógica",MessageBoxButton.YesNo,MessageBoxImage.Question) != MessageBoxResult.Yes) return;
            shell.Db.Write("dbo.usp_"+Entity.Name+"_Eliminar",false,new SqlParameter("@"+Entity.Key,SqlDbType.Int) { Value=selected.Value });
            shell.Refresh(this); shell.Notify("Baja lógica realizada: Activo = 0. El registro se conserva en SQL Server.");
        }
    }
    public sealed class SearchView
    {
        public DockPanel Root; private Shell shell; private TextBox contact=new TextBox { MaxLength=40 }, city=new TextBox { MaxLength=30 }; private DataGrid grid=Ui.Grid();
        public SearchView(Shell shell)
        {
            this.shell=shell; Root=new DockPanel { Margin=new Thickness(18) }; var top=new StackPanel(); DockPanel.SetDock(top,Dock.Top); Root.Children.Add(top);
            top.Children.Add(Ui.Title("Buscar proveedores activos")); top.Children.Add(new TextBlock { Text="Coincidencias parciales por contacto y ciudad. Ambos filtros se combinan con AND.",Margin=new Thickness(0,0,0,15) });
            var form=new WrapPanel(); form.Children.Add(Ui.Labeled("Nombre de contacto",contact,300)); form.Children.Add(Ui.Labeled("Ciudad",city,240)); top.Children.Add(form);
            var buttons=new StackPanel { Orientation=Orientation.Horizontal }; buttons.Children.Add(Ui.Button("Buscar",delegate { shell.Run(delegate { shell.RequireDb(); Load(); }); }));
            buttons.Children.Add(Ui.Button("Limpiar filtros",delegate { contact.Clear(); city.Clear(); if(shell.Db!=null) shell.Run(Load); })); top.Children.Add(buttons); Root.Children.Add(grid);
        }
        public void SetData(DataTable table) { grid.ItemsSource=table.DefaultView; }
        public void Load() { SetData(shell.Db.Read("dbo.usp_Proveedores_Buscar",DataAccess.Text("@NombreContacto",40,contact.Text),DataAccess.Text("@Ciudad",30,city.Text))); }
    }
    public sealed class ReportView
    {
        public DockPanel Root; private Shell shell; private DatePicker from=new DatePicker { SelectedDate=new DateTime(2026,8,1) }, to=new DatePicker { SelectedDate=new DateTime(2026,8,31) };
        private DataGrid grid=Ui.Grid(); private TextBlock total=new TextBlock { Margin=new Thickness(0,12,0,0), FontWeight=FontWeights.SemiBold };
        public ReportView(Shell shell)
        {
            this.shell=shell; Root=new DockPanel { Margin=new Thickness(18) }; var top=new StackPanel(); DockPanel.SetDock(top,Dock.Top); Root.Children.Add(top);
            top.Children.Add(Ui.Title("Detalles de pedidos por fechas")); top.Children.Add(new TextBlock { Text="Fecha del pedido · Incluye ambos extremos · Solo pedidos activos",Margin=new Thickness(0,0,0,15) });
            var form=new WrapPanel(); form.Children.Add(Ui.Labeled("Desde",from,240)); form.Children.Add(Ui.Labeled("Hasta",to,240)); top.Children.Add(form);
            top.Children.Add(Ui.Button("Consultar reporte",delegate { shell.Run(delegate { shell.RequireDb(); Load(); }); },"PrimaryButton")); top.Children.Add(total); Root.Children.Add(grid);
        }
        public void SetData(DataTable table)
        {
            grid.ItemsSource=table.DefaultView; decimal sum=0; foreach(DataRow row in table.Rows) sum+=Convert.ToDecimal(row["Importe"]);
            total.Text=table.Rows.Count+" detalles · Importe total: "+sum.ToString("N2");
        }
        public void Load()
        {
            if(!from.SelectedDate.HasValue || !to.SelectedDate.HasValue || from.SelectedDate>to.SelectedDate) throw new ArgumentException("Seleccione Desde y Hasta en orden válido.");
            SetData(shell.Db.Read("dbo.usp_DetallePedidos_PorFechas",DataAccess.Date("@Desde",from.SelectedDate.Value),DataAccess.Date("@Hasta",to.SelectedDate.Value)));
        }
    }
}
