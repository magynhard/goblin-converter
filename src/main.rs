use gtk::prelude::*;
use gtk::{Application, ApplicationWindow, Box, Button, ComboBoxText, Dialog, Entry, FileChooserAction, FileChooserDialog, Label, Orientation, ResponseType, Scale};
use std::process::Command;
use glib::clone;

fn main() {
    let application = Application::new(Some("com.example.Goblin"), Default::default());

    application.connect_activate(|app| {
        let window = ApplicationWindow::new(app);
        window.set_title("Goblin");
        window.set_default_size(400, 300);

        let vbox = Box::new(Orientation::Vertical, 10);
        vbox.set_margin_top(20);
        vbox.set_margin_bottom(20);
        vbox.set_margin_start(20);
        vbox.set_margin_end(20);

        let source_button = Button::with_label("Select Source File (PDF)");
        let output_button = Button::with_label("Select Output File (ODF)");

        let source_entry = Entry::new();
        source_entry.set_text("No file selected");

        let output_entry = Entry::new();
        output_entry.set_text("No file selected");

        source_button.connect_clicked(clone!(@weak window, @weak source_entry => move |_| {
            open_file_dialog(&window, "Select PDF Source File", FileChooserAction::Open, &source_entry);
        }));

        output_button.connect_clicked(clone!(@weak window, @weak output_entry => move |_| {
            open_file_dialog(&window, "Select Output ODF File", FileChooserAction::Save, &output_entry);
        }));

        let dropdown = ComboBoxText::new();
        dropdown.append_text("Monochrome");
        dropdown.set_active(Some(0));

        vbox.append(&Label::new(Some("Conversion Mode:")));
        vbox.append(&dropdown);

        let adjustment = gtk::Adjustment::new(300.0, 50.0, 500.0, 25.0, 25.0, 0.0);
        let density_scale = Scale::new(Orientation::Horizontal, Some(&adjustment));
        density_scale.set_value(300.0);
        density_scale.set_draw_value(true);
        density_scale.set_value_pos(gtk::PositionType::Top);

        density_scale.connect_value_changed(clone!(@weak adjustment => move |scale| {
            let value = scale.value();
            let step = adjustment.step_increment();
            let snapped_value = (value / step).round() * step;
            if value != snapped_value {
                adjustment.set_value(snapped_value);
            }
        }));

        vbox.append(&Label::new(Some("Density (default 300):")));
        vbox.append(&density_scale);

        vbox.append(&Label::new(Some("Source File:")));
        vbox.append(&source_entry);
        vbox.append(&source_button);

        vbox.append(&Label::new(Some("Output File:")));
        vbox.append(&output_entry);
        vbox.append(&output_button);

        let convert_button = Button::with_label("Convert");
        vbox.append(&convert_button);

        convert_button.connect_clicked(clone!(@weak window, @weak source_entry, @weak output_entry, @weak dropdown, @weak density_scale => move |_| {
            let source_file = source_entry.text().to_string();
            let output_file = output_entry.text().to_string();
            let mode = dropdown.active_text().unwrap().to_string().to_lowercase();
            let density = density_scale.value() as i32;

            if source_file != "No file selected" && output_file != "No file selected" {
                let mode = if mode == "monochrome" { "monochrome" } else { "monochrome" };
                let command = format!("magick -density {} {} -threshold 66% -{} -strip -compress Fax {}", density, shell_escape::escape(source_file.into()), mode, shell_escape::escape(output_file.into()));
                Command::new("sh")
                    .arg("-c")
                    .arg(command)
                    .output()
                    .expect("failed to execute process");
                show_custom_dialog(&window, "Conversion Complete!", gtk::MessageType::Info);
            } else {
                show_custom_dialog(&window, "Please select both source and output files.", gtk::MessageType::Error);
            }
        }));

        window.set_child(Some(&vbox));
        window.show();
    });

    application.run();
}

fn open_file_dialog(parent: &ApplicationWindow, title: &str, action: FileChooserAction, entry: &Entry) {
    let dialog = FileChooserDialog::new(Some(title), Some(parent), action);
    dialog.add_button("_Cancel", ResponseType::Cancel);
    dialog.add_button("_Open", ResponseType::Accept);

    dialog.connect_response(clone!(@weak entry => move |d, response| {
        if response == ResponseType::Accept {
            if let Some(file) = d.file() {
                entry.set_text(file.path().unwrap().to_str().unwrap());
            }
        }
        d.close();
    }));

    dialog.show();
}

fn show_custom_dialog(parent: &ApplicationWindow, text: &str, message_type: gtk::MessageType) {
    let dialog = Dialog::with_buttons(
        Some(if message_type == gtk::MessageType::Info { "Information" } else { "Error" }),
        Some(parent),
        gtk::DialogFlags::MODAL,
        &[("OK", ResponseType::Ok)],
    );
    dialog.set_default_size(300, 100);

    let content_area = dialog.content_area();
    let label = Label::new(Some(text));
    content_area.append(&label);

    dialog.connect_response(|d, _| {
        d.close();
    });

    dialog.show();
}