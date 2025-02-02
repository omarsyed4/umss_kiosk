//
//  GoogleAddressAutocompleteView.swift
//  UMSS
//
//  Created by Omar Syed on 2/1/25.
//


import SwiftUI
import GooglePlaces

struct GoogleAddressAutocompleteView: UIViewControllerRepresentable {
    @Binding var address: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator
        print("[DEBUG] GoogleAddressAutocompleteView: Created GMSAutocompleteViewController")
        return autocompleteController
    }

    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {
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
            let selectedAddress = place.formattedAddress ?? ""
            print("[DEBUG] GoogleAddressAutocompleteView: didAutocompleteWith place: \(selectedAddress)")
            parent.address = selectedAddress
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
