import { Request } from "express";
export interface Permission {
  // Define the structure of each permission object
  // Adjust the types according to the actual structure of each permission
  name: string;
  description: string;
  // Add more properties if necessary
}

export interface User {
  user_id: string;
  user_email: string;
  user_fname: string;
  user_lname: string;
  user_nationality: string;
  user_permissions: Permission; // Array of Permission objects
}

export interface ExtendedRequest extends Request {
    user: string;
    email: string;
    firstName: string;
    lastName: string;
    nationality: string;
    permissions: Permission; // Array of Permission objects
  }