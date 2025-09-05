import AuthForm from "@/components/auth/AuthForm";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import Link from "next/link";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background px-4">
      <div className="mx-auto w-full max-w-sm">
        <Card>
          <CardHeader className="text-center">
            <CardTitle className="font-headline text-2xl">Bem-vindo de Volta</CardTitle>
            <CardDescription>
              Digite suas credenciais para acessar sua biblioteca.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <AuthForm type="login" />
          </CardContent>
        </Card>
        <p className="mt-4 text-center text-sm text-muted-foreground">
          Não tem uma conta?{" "}
          <Link href="/signup" className="font-semibold text-primary underline-offset-4 hover:underline">
            Cadastre-se
          </Link>
        </p>
      </div>
    </div>
  );
}
