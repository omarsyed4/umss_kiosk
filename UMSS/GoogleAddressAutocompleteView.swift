import SwiftUI
import GooglePlaces

struct GoogleAddressAutocompleteView: UIViewControllerRepresentable {
    // Bindings for each address component in your patient model.
    @Binding var rawAddress: String       // Full formatted address from Google
    @Binding var streetAddress: String      // Street (number + route)
    @Binding var city: String
    @Binding var state: String
    @Binding var zip: String
    @Binding var cityState: String         // Combined "City, State
    @Binding var cityStateZip: String       // Combined "City, State ZIP"
    
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator
        print("[DEBUG] GoogleAddressAutocompleteView: Created GMSAutocompleteViewController")
        return autocompleteController
    }

    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {
        // No update needed.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        let parent: GoogleAddressAutocompleteView

        init(_ parent: GoogleAddressAutocompleteView) {
            self.parent = parent
        }

        // Called when the user selects a place.
        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            // Get the full formatted address.
            let selectedAddress = place.formattedAddress ?? ""
            print("[DEBUG] GoogleAddressAutocompleteView: didAutocompleteWith place: \(selectedAddress)")
            
            // Assign the full address.
            parent.rawAddress = selectedAddress

            // Extract the individual address components.
            if let components = place.addressComponents {
                var streetNumber = ""
                var route = ""
                var city = ""
                var state = ""
                var postalCode = ""

                // Iterate over the address components provided by Google.
                for component in components {
                    if component.types.contains("street_number") {
                        streetNumber = component.name
                    }
                    if component.types.contains("route") {
                        route = component.name
                    }
                    if component.types.contains("locality") {
                        city = component.name
                    }
                    if component.types.contains("administrative_area_level_1") {
                        // Use shortName for abbreviated state code (e.g., "FL").
                        state = component.shortName ?? component.name
                    }
                    if component.types.contains("postal_code") {
                        postalCode = component.name
                    }
                }
                
                // Combine street number and route.
                let street = "\(streetNumber) \(route)".trimmingCharacters(in: .whitespaces)
                parent.streetAddress = street
                parent.city = city
                parent.state = state
                parent.zip = postalCode
                
                // Build the combined "City, State ZIP" string.
                if !city.isEmpty && !state.isEmpty && !postalCode.isEmpty {
                    parent.cityStateZip = "\(city), \(state) \(postalCode)"
                    parent.cityState = "\(city), \(state)"
                } else if !city.isEmpty && !state.isEmpty {
                    parent.cityStateZip = "\(city), \(state)"
                    parent.cityState = "\(city), \(state)"
                } else {
                    parent.cityStateZip = ""
                }
                
                // Print each component for debugging.
                print("[DEBUG] GoogleAddressAutocompleteView: Street: \(street)")
                print("[DEBUG] GoogleAddressAutocompleteView: City: \(city)")
                print("[DEBUG] GoogleAddressAutocompleteView: State: \(state)")
                print("[DEBUG] GoogleAddressAutocompleteView: Postal Code: \(postalCode)")
                print("[DEBUG] GoogleAddressAutocompleteView: CityStateZip: \(parent.cityStateZip)")
            } else {
                print("[DEBUG] GoogleAddressAutocompleteView: No address components found.")
                // Optionally clear the fields.
                parent.streetAddress = ""
                parent.city = ""
                parent.state = ""
                parent.zip = ""
                parent.cityStateZip = ""
            }

            // Dismiss the autocomplete view.
            parent.isPresented = false
            viewController.dismiss(animated: true) {
                print("[DEBUG] GoogleAddressAutocompleteView: Autocomplete view dismissed")
            }
        }

        // Called if there is an error.
        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            let nsError = error as NSError
            print("[DEBUG] GoogleAddressAutocompleteView: didFailAutocompleteWithError: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code))")
            parent.isPresented = false
            viewController.dismiss(animated: true, completion: nil)
        }

        // Called when the user cancels the operation.
        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            print("[DEBUG] GoogleAddressAutocompleteView: Autocomplete cancelled")
            parent.isPresented = false
            viewController.dismiss(animated: true, completion: nil)
        }

        // Optional: Turn the network activity indicator on/off.
        func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
            print("[DEBUG] GoogleAddressAutocompleteView: Requesting autocomplete predictions")
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
            print("[DEBUG] GoogleAddressAutocompleteView: Updated autocomplete predictions")
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
